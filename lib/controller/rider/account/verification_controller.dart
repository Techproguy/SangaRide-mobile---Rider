import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/upload_purposes.dart';
import 'package:sanga_ride/core/api/verification_endpoints.dart';
import 'package:sanga_ride/core/services/image_compression_service.dart';
import 'package:sanga_ride/core/services/package_photo_service.dart';
import 'package:sanga_ride/core/services/selfie_verifier.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage/draft_keys.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaSelfieOutcome;

class VerificationController extends GetxController {
  static const Duration _pollEvery = Duration(seconds: 10);
  static const String _draftKey = DraftKeys.verificationDocument;

  final _api = Get.find<ApiService>();
  final _selfie = SelfieVerifier();

  final Rx<VerificationState> _state = Rx<VerificationState>(const VerificationLoading());
  final Rx<DocumentDraft> _draft = Rx<DocumentDraft>(const DocumentDraft());
  final RxBool _isSubmitting = false.obs;
  final Map<DocumentSide, Epoch> _epochs = {for (final side in DocumentSide.values) side: Epoch()};

  LivePoller? _poller;
  Mutation<Verification>? _submission;
  VerificationStatus? _syncedStatus;

  Rx<VerificationState> get stateRx => _state;

  VerificationState get state => _state.value;

  DocumentDraft get draft => _draft.value;

  bool get isSubmitting => _isSubmitting.value;

  VerificationStatus? get status => _state.value.verificationOrNull?.status;

  VerificationItem? get documentItem => _state.value.verificationOrNull?.documentItem;

  List<IdDocumentType> get documentTypes {
    final accepted = documentItem?.documentTypes ?? const <String>[];
    if (accepted.isEmpty) return IdDocumentType.values;
    return [
      for (final type in IdDocumentType.values)
        if (accepted.contains(type.code)) type,
    ];
  }

  @override
  void onClose() {
    _stopPolling();
    _submission?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    try {
      await _fetchStatus();
    } on Object catch (error) {
      if (_state.value is! VerificationLoaded) _state.value = VerificationFailed(VerificationProblem.of(error));
    }
  }

  Future<void> retry() async {
    _state.value = const VerificationLoading();
    await load();
  }

  void startDocument() {
    for (final side in DocumentSide.values) {
      _nextEpoch(side);
    }
    _draft.value = _hydratedDraft();
  }

  void releaseDocument() {
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
    _persistDraft();
  }

  Future<void> pickPhoto(DocumentSide side, PhotoSource source) async {
    if (draft.sideOf(side).isBusy || draft.isSubmitting) return;
    final epoch = _nextEpoch(side);
    final before = draft.sideOf(side);
    try {
      final path = await PackagePhotoService.pick(
        source,
        onPicked: () {
          if (_isCurrent(side, epoch)) _setSide(side, const PhotoPreparing());
        },
      );
      if (!_isCurrent(side, epoch)) {
        await ImageCompressionService.discard(path);
        return;
      }
      if (path == null) {
        if (before is PhotoPreparing) _setSide(side, const PhotoNone());
        return;
      }
      await ImageCompressionService.discard(before.localPath);
      await _upload(side, path, epoch);
    } on PhotoException catch (error) {
      if (_isCurrent(side, epoch)) _setSide(side, PhotoFailed(failure: error.failure));
    } on Object {
      if (_isCurrent(side, epoch)) _setSide(side, const PhotoFailed(failure: DeliveryFailure.unreadablePhoto));
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

  void clearPermissionFailures() {
    for (final side in DocumentSide.values) {
      final state = draft.sideOf(side);
      final isPermission = state is PhotoFailed && state.failure.opensSettings;
      if (isPermission) _setSide(side, const PhotoNone());
    }
  }

  Future<SangaSelfieOutcome> verifySelfie(String photoPath) async {
    final outcome = await _selfie.verify(photoPath);
    if (outcome == SangaSelfieOutcome.passed) await load();
    return outcome;
  }

  Future<bool> submitDocument() async {
    final current = draft;
    final type = current.type;
    final front = current.front;
    final back = current.back;
    final itemId = documentItem?.id;
    if (!current.isReady || type == null || front is! PhotoUploaded || isSubmitting) return false;
    if (itemId == null) {
      _draft.value = current.copyWith(problem: VerificationProblem.unknown);
      return false;
    }
    _draft.value = current.copyWith(isSubmitting: true, clearProblem: true, missing: const []);
    return _submit({
      'documents': [
        {
          'itemId': itemId,
          'type': type.code,
          'frontUploadId': front.id,
          if (type.hasBack && back is PhotoUploaded) 'backUploadId': back.id,
        },
      ],
    });
  }

  Future<bool> submitReview() async {
    if (isSubmitting) return false;
    return _submit(const {});
  }

  Future<bool> _submit(Map<String, dynamic> body) async {
    if (ConnectionMonitor.current?.isOnline == false) {
      _draft.value = _draft.value.copyWith(isSubmitting: false, problem: VerificationProblem.connection);
      return false;
    }
    _isSubmitting.value = true;
    try {
      final pending = _submission;
      final isChecking = pending != null && pending.state.value is MutationUnknown<Verification>;
      final mutation = isChecking ? pending : _newSubmission(body);
      final result = isChecking ? await mutation.recheck() : await mutation.start();
      return _settleSubmission(result);
    } finally {
      _isSubmitting.value = false;
    }
  }

  Mutation<Verification> _newSubmission(Map<String, dynamic> body) {
    _submission?.dispose();
    return _submission = Mutation<Verification>(
      intent: IdempotencyIntent.verificationSubmit,
      run: (key) async {
        final response = await _api.post(VerificationEndpoints.submit, data: body, key: key, suppressErrorToast: true);
        return Verification.fromJson(response.dataMapOrEmpty);
      },
      reconcile: () async {
        final response = await _api.get(VerificationEndpoints.status, suppressErrorToast: true);
        final verification = Verification.fromJson(response.dataMapOrEmpty);
        final accepted =
            verification.status == VerificationStatus.pending || verification.status == VerificationStatus.verified;
        return accepted ? ReconciledDone(verification) : const ReconciledNotDone<Verification>();
      },
    );
  }

  bool _settleSubmission(MutationState<Verification> result) {
    switch (result) {
      case MutationDone<Verification>(:final value):
        _applyVerification(value);
        _draft.value = _draft.value.copyWith(isSubmitting: false);
        unawaited(SessionStorage.drafts.remove(_draftKey));
        return true;
      case MutationRejected<Verification>(:final error):
        final problem = VerificationProblem.of(error);
        _draft.value = _draft.value.copyWith(isSubmitting: false, problem: problem, missing: _missingOf(error));
        if (problem == VerificationProblem.incomplete) unawaited(load());
      case MutationFailed<Verification>(:final error):
        _draft.value = _draft.value.copyWith(isSubmitting: false, problem: VerificationProblem.of(error));
      case MutationUnknown<Verification>():
        _draft.value = _draft.value.copyWith(isSubmitting: false, problem: VerificationProblem.unconfirmed);
      case MutationIdle<Verification>() || MutationRunning<Verification>() || MutationChecking<Verification>():
        _draft.value = _draft.value.copyWith(isSubmitting: false);
    }
    return false;
  }

  Future<void> _upload(DocumentSide side, String path, int epoch) async {
    _setSide(side, PhotoUploading(path: path, progress: 0));
    try {
      final ref = await _api.upload(
        VerificationEndpoints.uploads,
        file: File(path),
        purpose: UploadPurposes.idDocument,
        suppressErrorToast: true,
        onProgress: (sent, total) {
          if (_isCurrent(side, epoch) && total > 0) _setSide(side, PhotoUploading(path: path, progress: sent / total));
        },
      );
      if (!_isCurrent(side, epoch)) return;
      _setSide(side, PhotoUploaded(path: path, id: ref.id, url: ref.url));
    } on Object catch (error) {
      if (_isCurrent(side, epoch)) _setSide(side, PhotoFailed(failure: DeliveryFailure.of(error), path: path));
    }
  }

  Future<void> _fetchStatus() async {
    final response = await _api.get(VerificationEndpoints.status, suppressErrorToast: true);
    _applyVerification(Verification.fromJson(response.dataMapOrEmpty));
  }

  void _applyVerification(Verification verification) {
    _state.value = VerificationLoaded(verification);
    _syncPoller(verification);
    _syncAccountStatus(verification.status);
  }

  void _syncPoller(Verification verification) {
    if (verification.status != VerificationStatus.pending) return _stopPolling();
    if (_poller != null) return;
    final poller = LivePoller(fetch: _fetchStatus, interval: _pollEvery);
    _poller = poller;
    poller.start();
  }

  void _stopPolling() {
    final poller = _poller;
    _poller = null;
    if (poller != null) Future<void>.microtask(poller.dispose);
  }

  int _nextEpoch(DocumentSide side) => _epochs[side]!.next();

  bool _isCurrent(DocumentSide side, int epoch) => _epochs[side]!.isCurrent(epoch);

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
    _persistDraft();
  }

  void _persistDraft() {
    final current = draft;
    final front = current.front;
    final back = current.back;
    final hasUploads = front is PhotoUploaded || back is PhotoUploaded;
    if (!hasUploads && current.type == null) {
      unawaited(SessionStorage.drafts.remove(_draftKey));
      return;
    }
    unawaited(
      SessionStorage.drafts.write(_draftKey, {
        'type': ?current.type?.code,
        if (front is PhotoUploaded) 'front': _refOf(front),
        if (back is PhotoUploaded) 'back': _refOf(back),
      }),
    );
  }

  Map<String, dynamic> _refOf(PhotoUploaded photo) => {'id': photo.id, 'url': photo.url, 'path': photo.path};

  DocumentDraft _hydratedDraft() {
    final saved = SessionStorage.drafts.read(_draftKey);
    if (saved == null) return const DocumentDraft();
    final reader = JsonReader(saved);
    return DocumentDraft(
      type: IdDocumentType.fromCode(reader.strOrNull('type')),
      front: _uploadedOf(reader.objectOrNull('front')) ?? const PhotoNone(),
      back: _uploadedOf(reader.objectOrNull('back')) ?? const PhotoNone(),
    );
  }

  PhotoUploaded? _uploadedOf(JsonReader? reader) {
    final id = reader?.strOrNull('id');
    if (reader == null || id == null) return null;
    return PhotoUploaded(path: reader.strOr('path', ''), id: id, url: reader.strOr('url', ''));
  }

  void _syncAccountStatus(VerificationStatus status) {
    final previous = _syncedStatus;
    _syncedStatus = status;
    if (previous != null && previous != status && Get.isRegistered<AccountController>()) {
      unawaited(Get.find<AccountController>().load());
    }
  }

  List<String> _missingOf(ApiException error) {
    final nested = error.data['data'];
    final raw = error.data['missing'] ?? (nested is Map ? nested['missing'] : null);
    return raw is List ? [for (final id in raw) '$id'] : const [];
  }
}
