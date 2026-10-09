import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/verification_endpoints.dart';
import 'package:sanga_ride/core/services/image_compression_service.dart';
import 'package:sanga_ride/core/services/package_photo_service.dart';
import 'package:sanga_ride/model/models.dart';

class VerificationController extends GetxController {
  static const Duration _pollEvery = Duration(seconds: 3);
  static const String _documentPurpose = 'id_document';
  static const String _documentItemId = 'national_id';

  final _api = Get.find<ApiService>();

  final Rx<VerificationState> _state = Rx<VerificationState>(const VerificationLoading());
  final Rx<DocumentDraft> _draft = Rx<DocumentDraft>(const DocumentDraft());
  final RxBool _isSubmitting = false.obs;
  final Map<DocumentSide, int> _epochs = {DocumentSide.front: 0, DocumentSide.back: 0};

  Timer? _poll;
  VerificationStatus? _syncedStatus;

  Rx<VerificationState> get stateRx => _state;

  VerificationState get state => _state.value;

  DocumentDraft get draft => _draft.value;

  bool get isSubmitting => _isSubmitting.value;

  VerificationStatus? get status => _state.value.verificationOrNull?.status;

  @override
  void onClose() {
    _poll?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    try {
      final response = await _api.get(VerificationEndpoints.status, options: quietOptions);
      final verification = Verification.fromJson(dataOf(response));
      _state.value = VerificationLoaded(verification);
      _schedulePoll(verification);
      _syncAccountStatus(verification.status);
    } catch (error) {
      log('verification load failed: $error');
      if (_state.value is! VerificationLoaded) _state.value = VerificationFailed(_problemOf(error));
    }
  }

  Future<void> retry() async {
    _state.value = const VerificationLoading();
    await load();
  }

  void stopPolling() => _poll?.cancel();

  void startDocument() {
    for (final side in DocumentSide.values) {
      _epochs[side] = (_epochs[side] ?? 0) + 1;
    }
    _discardDraftFiles();
    _draft.value = const DocumentDraft();
  }

  void releaseDocument() {
    _discardDraftFiles();
    for (final side in DocumentSide.values) {
      _nextEpoch(side);
    }
    _draft.value = const DocumentDraft();
  }

  void selectType(IdDocumentType type) {
    final current = draft;
    if (current.isSubmitting || current.type == type) return;
    if (!type.hasBack) _clearSide(DocumentSide.back);
    _draft.value = _draft.value.copyWith(type: type, clearProblem: true);
  }

  Future<void> pickPhoto(DocumentSide side, PhotoSource source) async {
    if (draft.sideOf(side).isBusy || draft.isSubmitting) return;
    final epoch = _nextEpoch(side);
    final before = draft.sideOf(side);
    try {
      final path = await PackagePhotoService.pick(
        source,
        onPicked: () {
          if (epoch == _epochs[side]) _setSide(side, const PhotoPreparing());
        },
      );
      if (epoch != _epochs[side]) {
        await ImageCompressionService.discard(path);
        return;
      }
      if (path == null) return;
      await ImageCompressionService.discard(before.localPath);
      await _upload(side, path, epoch);
    } on PhotoException catch (error) {
      if (epoch == _epochs[side]) _setSide(side, PhotoFailed(failure: error.failure));
    } catch (error) {
      log('pick id photo failed: $error');
      if (epoch == _epochs[side]) _setSide(side, const PhotoFailed(failure: DeliveryFailure.unreadablePhoto));
    }
  }

  Future<void> retryUpload(DocumentSide side) async {
    final path = draft.sideOf(side).localPath;
    if (path == null || draft.sideOf(side).isBusy) return;
    await _upload(side, path, _nextEpoch(side));
  }

  Future<void> removePhoto(DocumentSide side) async {
    _nextEpoch(side);
    final path = draft.sideOf(side).localPath;
    _setSide(side, const PhotoNone());
    await ImageCompressionService.discard(path);
  }

  Future<bool> verifySelfie(String photoPath) async {
    try {
      final response = await _api.post(AppEndpoints.selfie, data: {'photo': photoPath}, options: quietOptions);
      final passed = dataOf(response)['status'] == 'verified';
      if (passed) await load();
      return passed;
    } catch (error) {
      log('selfie failed: $error');
      return false;
    }
  }

  Future<bool> submitDocument() async {
    final current = draft;
    final type = current.type;
    final front = current.front;
    final back = current.back;
    if (!current.isReady || type == null || front is! PhotoUploaded || isSubmitting) return false;
    _draft.value = current.copyWith(isSubmitting: true, clearProblem: true, missing: const []);
    final isSent = await _submit({
      'documents': [
        {
          'itemId': _documentItemId,
          'type': type.code,
          'frontUploadId': front.id,
          if (type.hasBack && back is PhotoUploaded) 'backUploadId': back.id,
        },
      ],
    });
    return isSent;
  }

  Future<bool> submitReview() async {
    if (isSubmitting) return false;
    return _submit(const {});
  }

  Future<bool> _submit(Map<String, dynamic> body) async {
    _isSubmitting.value = true;
    try {
      final response = await _api.post(VerificationEndpoints.submit, data: body, options: quietOptions);
      final verification = Verification.fromJson(dataOf(response));
      _state.value = VerificationLoaded(verification);
      _schedulePoll(verification);
      _syncAccountStatus(verification.status);
      _draft.value = _draft.value.copyWith(isSubmitting: false);
      return true;
    } catch (error) {
      log('verification submit failed: $error');
      final problem = _problemOf(error);
      _draft.value = _draft.value.copyWith(isSubmitting: false, problem: problem, missing: _missingOf(error));
      if (problem == VerificationProblem.incomplete) await load();
      return false;
    } finally {
      _isSubmitting.value = false;
    }
  }

  Future<void> _upload(DocumentSide side, String path, int epoch) async {
    _setSide(side, PhotoUploading(path: path, progress: 0));
    try {
      final response = await _api.uploadFile(
        VerificationEndpoints.uploads,
        file: File(path),
        fields: {'purpose': _documentPurpose},
        suppressErrorToast: true,
        onSendProgress: (sent, total) {
          if (epoch == _epochs[side] && total > 0) _setSide(side, PhotoUploading(path: path, progress: sent / total));
        },
      );
      if (epoch != _epochs[side]) return;
      final data = dataOf(response);
      _setSide(side, PhotoUploaded(path: path, id: data['id'] as String, url: data['url'] as String));
    } on ApiException catch (error) {
      log('id upload failed: $error');
      if (epoch == _epochs[side]) {
        _setSide(side, PhotoFailed(failure: DeliveryFailure.fromCode(error.code), path: path));
      }
    } catch (error) {
      log('id upload failed: $error');
      if (epoch == _epochs[side]) _setSide(side, PhotoFailed(failure: DeliveryFailure.connection, path: path));
    }
  }

  int _nextEpoch(DocumentSide side) => _epochs[side] = (_epochs[side] ?? 0) + 1;

  void _clearSide(DocumentSide side) {
    _nextEpoch(side);
    final path = draft.sideOf(side).localPath;
    _setSide(side, const PhotoNone());
    ImageCompressionService.discard(path);
  }

  void _setSide(DocumentSide side, PackagePhotoState state) {
    _draft.value = side == DocumentSide.front
        ? _draft.value.copyWith(front: state, clearProblem: true)
        : _draft.value.copyWith(back: state, clearProblem: true);
  }

  void _discardDraftFiles() {
    for (final side in DocumentSide.values) {
      ImageCompressionService.discard(draft.sideOf(side).localPath);
    }
  }

  void _syncAccountStatus(VerificationStatus status) {
    final previous = _syncedStatus;
    _syncedStatus = status;
    if (previous != null && previous != status && Get.isRegistered<AccountController>()) {
      unawaited(Get.find<AccountController>().load());
    }
  }

  List<String> _missingOf(Object error) {
    if (error is! ApiException) return const [];
    final nested = error.data['data'];
    final raw = error.data['missing'] ?? (nested is Map ? nested['missing'] : null);
    return raw is List ? [for (final id in raw) '$id'] : const [];
  }

  void _schedulePoll(Verification verification) {
    _poll?.cancel();
    if (verification.status != VerificationStatus.pending) return;
    _poll = Timer(_pollEvery, load);
  }

  VerificationProblem _problemOf(Object error) =>
      error is ApiException ? VerificationProblem.fromCode(error.code) : VerificationProblem.connection;
}
