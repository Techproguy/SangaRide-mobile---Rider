import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/controller/rider/account/account_bindings.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/api/account_endpoints.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/services/image_compression_service.dart';
import 'package:sanga_ride/core/services/package_photo_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class AccountController extends GetxController {
  static const String _photoPurpose = 'profile_photo';

  final _api = Get.find<ApiService>();
  final _users = Get.find<UserController>();

  final Rx<AccountState> _state = Rx<AccountState>(const AccountLoading());
  final Rx<DeleteAccountState> _delete = Rx<DeleteAccountState>(const DeleteIdle());
  final Rx<DeletionPreviewState> _preview = Rx<DeletionPreviewState>(const DeletionPreviewLoading());

  String? _uploadedPhotoId;
  IdempotencyKey? _photoLinkKey;
  Mutation<DateTime?>? _deletion;
  DateTime? _loadedAt;
  int _loadEpoch = 0;

  AccountState get state => _state.value;

  DeleteAccountState get deleteState => _delete.value;

  DeletionPreviewState get previewState => _preview.value;

  Account? get account => _state.value.accountOrNull;

  @override
  void onClose() {
    _deletion?.dispose();
    super.onClose();
  }

  Future<void> loadIfStale() async {
    final loadedAt = _loadedAt;
    final isFresh =
        _state.value is AccountLoaded &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < const Duration(seconds: 20);
    if (!isFresh) await load();
  }

  Future<void> load() async {
    final epoch = ++_loadEpoch;
    if (_state.value is! AccountLoaded) _state.value = const AccountLoading();
    try {
      final response = await _api.get(AccountEndpoints.me, options: quietOptions);
      if (epoch != _loadEpoch) return;
      _loadedAt = DateTime.now();
      await apply(dataOf(response));
    } on Object catch (error) {
      if (epoch == _loadEpoch && _state.value is! AccountLoaded) _state.value = AccountFailed(AccountProblem.of(error));
    }
  }

  Future<void> retry() async {
    _state.value = const AccountLoading();
    await load();
  }

  Future<void> apply(Map<String, dynamic> json) async {
    final account = Account.fromJson(json);
    final current = _state.value;
    _state.value = current is AccountLoaded ? current.copyWith(account: account) : AccountLoaded(account);
    await _users.setUser(account.toUserModel());
  }

  Future<AccountProblem?> saveProfile(Map<String, dynamic> fields) async {
    try {
      final response = await _api.patch(AccountEndpoints.me, data: fields, options: quietOptions);
      await apply(dataOf(response));
      return null;
    } on Object catch (error) {
      return AccountProblem.of(error);
    }
  }

  void denyPhoto(PhotoSource source) {
    final problem = source == PhotoSource.camera ? AccountProblem.cameraDenied : AccountProblem.photosDenied;
    _patchLoaded((loaded) => loaded.copyWith(photoProblem: () => problem));
  }

  Future<void> changePhoto(PhotoSource source) async {
    final current = _state.value;
    if (current is! AccountLoaded || current.isUploadingPhoto) return;
    String? prepared;
    try {
      prepared = await PackagePhotoService.pick(
        source,
        onPicked: () => _patchLoaded((loaded) => loaded.copyWith(isUploadingPhoto: true, photoProblem: () => null)),
      );
      if (prepared == null) return;
      final ref = await _api.upload(
        AccountEndpoints.uploads,
        file: File(prepared),
        purpose: _photoPurpose,
        suppressErrorToast: true,
      );
      _uploadedPhotoId = ref.id;
      _photoLinkKey = IdempotencyKey.newFor('profile-photo');
      await _linkPhoto();
    } on PhotoException catch (error) {
      _patchLoaded((loaded) => loaded.copyWith(photoProblem: () => _photoProblemOf(error.failure)));
    } on Object catch (error) {
      _patchLoaded(
        (loaded) => loaded.copyWith(photoProblem: () => AccountProblem.of(error), hasPendingPhoto: _hasPendingPhoto),
      );
    } finally {
      await ImageCompressionService.discard(prepared);
      _patchLoaded((loaded) => loaded.copyWith(isUploadingPhoto: false));
    }
  }

  Future<void> retryPhoto() async {
    final current = _state.value;
    if (!_hasPendingPhoto || current is! AccountLoaded || current.isUploadingPhoto) return;
    _patchLoaded((loaded) => loaded.copyWith(isUploadingPhoto: true, photoProblem: () => null));
    try {
      await _linkPhoto();
    } on Object catch (error) {
      _patchLoaded(
        (loaded) => loaded.copyWith(photoProblem: () => AccountProblem.of(error), hasPendingPhoto: _hasPendingPhoto),
      );
    } finally {
      _patchLoaded((loaded) => loaded.copyWith(isUploadingPhoto: false));
    }
  }

  bool get _hasPendingPhoto => _uploadedPhotoId != null;

  Future<void> _linkPhoto() async {
    final response = await _api.post(
      AccountEndpoints.photo,
      data: {'uploadId': _uploadedPhotoId},
      key: _photoLinkKey,
      options: quietOptions,
    );
    _uploadedPhotoId = null;
    _photoLinkKey = null;
    await apply(dataOf(response));
    _patchLoaded((loaded) => loaded.copyWith(hasPendingPhoto: false));
  }

  void _patchLoaded(AccountLoaded Function(AccountLoaded loaded) change) {
    final latest = _state.value;
    if (latest is AccountLoaded) _state.value = change(latest);
  }

  void clearPhotoProblem() => _patchLoaded((loaded) => loaded.copyWith(photoProblem: () => null));

  Future<void> loadDeletionPreview() async {
    _preview.value = const DeletionPreviewLoading();
    try {
      final response = await _api.get(AccountEndpoints.deletionPreview, options: quietOptions);
      _preview.value = DeletionPreviewLoaded(DeletionPreview.fromJson(dataOf(response)));
    } on Object catch (error) {
      _preview.value = DeletionPreviewFailed(AccountProblem.of(error).message);
    }
  }

  Future<bool> deleteAccount({String? reason}) async {
    final current = _delete.value;
    if (current is DeleteDeleting) return false;
    if (current is DeleteUnknown) return _recheckDeletion();
    if (_isOffline) {
      _delete.value = const DeleteIdle(block: AccountProblem.connection);
      return false;
    }
    _delete.value = const DeleteDeleting();
    _deletion?.dispose();
    final mutation = _deletion = Mutation<DateTime?>(
      intent: 'delete-account',
      run: (key) async {
        final response = await _api.delete(
          AccountEndpoints.me,
          data: {'reason': reason},
          key: key,
          options: quietOptions,
        );
        return JsonReader(dataOf(response)).timeOrNull('deletesAt')?.toLocal();
      },
      reconcile: _reconcileDeletion,
    );
    return _settleDeletion(await mutation.start());
  }

  Future<bool> _recheckDeletion() async {
    final mutation = _deletion;
    if (mutation == null) {
      _delete.value = const DeleteIdle();
      return false;
    }
    _delete.value = const DeleteDeleting();
    return _settleDeletion(await mutation.recheck());
  }

  bool _settleDeletion(MutationState<DateTime?> result) {
    switch (result) {
      case MutationDone<DateTime?>(:final value):
        _delete.value = DeleteScheduled(value);
        return true;
      case MutationRejected<DateTime?>(:final error):
        _deletion?.reset();
        _delete.value = DeleteIdle(block: AccountProblem.of(error));
      case MutationFailed<DateTime?>(:final error):
        _delete.value = DeleteIdle(block: AccountProblem.of(error));
      case MutationUnknown<DateTime?>():
        _delete.value = const DeleteUnknown();
      case MutationIdle<DateTime?>() || MutationRunning<DateTime?>() || MutationChecking<DateTime?>():
        _delete.value = const DeleteIdle();
    }
    return false;
  }

  Future<Reconciled<DateTime?>> _reconcileDeletion() async {
    final response = await _api.get(AccountEndpoints.me, options: quietOptions);
    final deletesAt = JsonReader(dataOf(response)).timeOrNull('deletesAt');
    if (deletesAt == null) return const ReconciledNotDone<DateTime?>();
    return ReconciledDone<DateTime?>(deletesAt.toLocal());
  }

  bool get _isOffline => ConnectionMonitor.current?.isOnline == false;

  void resetDelete() {
    _deletion?.dispose();
    _deletion = null;
    _delete.value = const DeleteIdle();
  }

  Future<void> logout() async {
    await Get.find<AuthController>().logout();
    _state.value = const AccountLoading();
    _delete.value = const DeleteIdle();
    resetAccountAreaControllers();
  }

  AccountProblem _photoProblemOf(DeliveryFailure failure) => switch (failure) {
    DeliveryFailure.fileTooLarge => AccountProblem.photoTooLarge,
    DeliveryFailure.cameraDenied => AccountProblem.cameraDenied,
    DeliveryFailure.photosDenied => AccountProblem.photosDenied,
    _ => AccountProblem.photoUnreadable,
  };
}
