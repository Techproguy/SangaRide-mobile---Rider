import 'dart:developer';
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

class AccountController extends GetxController {
  static const String _photoPurpose = 'profile_photo';

  final _api = Get.find<ApiService>();
  final _users = Get.find<UserController>();

  final Rx<AccountState> _state = Rx<AccountState>(const AccountLoading());
  final Rx<DeleteAccountState> _delete = Rx<DeleteAccountState>(const DeleteIdle());

  AccountState get state => _state.value;

  DeleteAccountState get deleteState => _delete.value;

  Account? get account => _state.value.accountOrNull;

  Future<void> load() async {
    if (_state.value is! AccountLoaded) _state.value = const AccountLoading();
    try {
      final response = await _api.get(AccountEndpoints.me, options: quietOptions);
      await apply(dataOf(response));
    } catch (error) {
      log('account load failed: $error');
      if (_state.value is! AccountLoaded) _state.value = AccountFailed(_problemOf(error));
    }
  }

  Future<void> retry() async {
    _state.value = const AccountLoading();
    await load();
  }

  Future<void> apply(Map<String, dynamic> json) async {
    final current = _state.value;
    final account = Account.fromJson(json);
    _state.value = AccountLoaded(account, isUploadingPhoto: current is AccountLoaded && current.isUploadingPhoto);
    await _users.setUser(account.toUserModel());
  }

  Future<AccountProblem?> saveProfile(Map<String, dynamic> fields) async {
    try {
      final response = await _api.patch(AccountEndpoints.me, data: fields, options: quietOptions);
      await apply(dataOf(response));
      return null;
    } catch (error) {
      log('account update failed: $error');
      return _problemOf(error);
    }
  }

  Future<void> changePhoto(PhotoSource source) async {
    final current = _state.value;
    if (current is! AccountLoaded || current.isUploadingPhoto) return;
    String? prepared;
    try {
      prepared = await PackagePhotoService.pick(
        source,
        onPicked: () => _state.value = AccountLoaded(current.account, isUploadingPhoto: true),
      );
      if (prepared == null) return;
      final upload = await _api.uploadFile(
        AccountEndpoints.uploads,
        file: File(prepared),
        fields: {'purpose': _photoPurpose},
        suppressErrorToast: true,
      );
      final response = await _api.post(
        AccountEndpoints.photo,
        data: {'uploadId': dataOf(upload)['id']},
        options: quietOptions,
      );
      await apply(dataOf(response));
    } on PhotoException catch (error) {
      log('photo prepare failed: ${error.failure}');
      _state.value = AccountLoaded(current.account, photoProblem: _photoProblemOf(error.failure));
    } catch (error) {
      log('photo upload failed: $error');
      _state.value = AccountLoaded(current.account, photoProblem: _problemOf(error));
    } finally {
      await ImageCompressionService.discard(prepared);
      final latest = _state.value;
      if (latest is AccountLoaded && latest.isUploadingPhoto) {
        _state.value = AccountLoaded(latest.account, photoProblem: latest.photoProblem);
      }
    }
  }

  void clearPhotoProblem() {
    final current = _state.value;
    if (current is AccountLoaded && current.photoProblem != null) _state.value = AccountLoaded(current.account);
  }

  Future<bool> deleteAccount({String? reason}) async {
    if (_delete.value is DeleteDeleting) return false;
    _delete.value = const DeleteDeleting();
    try {
      final response = await _api.delete(AccountEndpoints.me, data: {'reason': reason}, options: quietOptions);
      _delete.value = DeleteScheduled(DateTime.parse('${dataOf(response)['deletesAt']}').toLocal());
      return true;
    } catch (error) {
      log('account delete failed: $error');
      _delete.value = DeleteIdle(block: _problemOf(error));
      return false;
    }
  }

  void resetDelete() => _delete.value = const DeleteIdle();

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

  AccountProblem _problemOf(Object error) =>
      error is ApiException ? AccountProblem.fromCode(error.code) : AccountProblem.connection;
}
