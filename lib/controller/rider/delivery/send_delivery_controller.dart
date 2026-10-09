import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/delivery_endpoints.dart';
import 'package:sanga_ride/core/api/upload_purposes.dart';
import 'package:sanga_ride/core/services/image_compression_service.dart';
import 'package:sanga_ride/core/services/package_photo_service.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage/draft_keys.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum SubmitCheck { ready, priceRefreshed, priceUnavailable, incomplete }

class SendDeliveryController extends GetxController {
  static const Duration draftLifetime = Duration(hours: 12);
  static const Duration persistDelay = Duration(milliseconds: 400);

  final _api = Get.find<ApiService>();
  final _ride = Get.find<RideRequestController>();

  final Rx<DeliveryCatalogState> _catalog = Rx<DeliveryCatalogState>(const DeliveryCatalogLoading());
  final Rx<DeliveryDraft> _draft = Rx<DeliveryDraft>(const DeliveryDraft());
  final Rx<PackagePhotoState> _photo = Rx<PackagePhotoState>(const PhotoNone());
  final Rx<DeliveryQuoteState> _quote = Rx<DeliveryQuoteState>(const QuoteIdle());
  final Rxn<DeliveryFailure> _recipientFailure = Rxn<DeliveryFailure>();
  Timer? _persistTimer;
  final Epoch _photoEpoch = Epoch();
  final Epoch _quoteEpoch = Epoch();
  String? _quoteSignature;
  String? _lastRecommendedTier;

  DeliveryCatalogState get catalogState => _catalog.value;

  DeliveryCatalog? get catalog => switch (catalogState) {
    DeliveryCatalogReady(:final catalog) => catalog,
    DeliveryCatalogLoading() || DeliveryCatalogFailed() => null,
  };

  DeliveryDraft get draft => _draft.value;

  PackagePhotoState get photo => _photo.value;

  DeliveryQuoteState get quoteState => _quote.value;

  DeliveryFailure? get recipientFailure => _recipientFailure.value;

  DeliveryKindOption? get kind => catalog?.kindOf(draft.kindId);

  bool get isDocuments => kind?.isDocuments ?? false;

  bool get isItemComplete => catalog != null && draft.isItemComplete(catalog!);

  bool get isHighValue => catalog?.isHighValue(draft.declaredValue) ?? false;

  bool get isPhotoRequired => !isDocuments;

  bool get canLeavePhotoStep => !photo.isBusy && (photo is PhotoUploaded || !isPhotoRequired);

  DeliveryQuote? get quote => switch (quoteState) {
    QuoteReady(:final quote) => quote,
    QuoteIdle() || QuoteLoading() || QuoteFailed() => null,
  };

  QuoteTier? get selectedTier => quote?.tierOf(draft.tierId);

  DeliveryTierInfo? get selectedTierInfo => catalog?.tierOf(draft.tierId);

  bool get isReadyToSubmit => selectedTier != null && draft.recipient != null && isItemComplete;

  @override
  void onClose() {
    _persistTimer?.cancel();
    ImageCompressionService.discard(photo.localPath);
    super.onClose();
  }

  void begin() {
    _photoEpoch.next();
    _quoteEpoch.next();
    ImageCompressionService.discard(photo.localPath);
    _draft.value = const DeliveryDraft();
    _photo.value = const PhotoNone();
    _quote.value = const QuoteIdle();
    _recipientFailure.value = null;
    _quoteSignature = null;
    _lastRecommendedTier = null;
    _restoreSavedDraft();
  }

  void _restoreSavedDraft() {
    final saved = SessionStorage.drafts.read(DraftKeys.deliveryDraft);
    if (saved == null) return;
    final reader = JsonReader.of(saved);
    final savedAt = reader.timeOrNull('savedAt');
    if (savedAt == null || DateTime.now().difference(savedAt) > draftLifetime) {
      unawaited(SessionStorage.drafts.remove(DraftKeys.deliveryDraft));
      return;
    }
    final recipient = reader.objectOrNull('recipient');
    _draft.value = DeliveryDraft(
      kindId: reader.strOrNull('kindId'),
      name: reader.strOr('name', ''),
      description: reader.strOr('description', ''),
      sizeId: reader.strOrNull('sizeId'),
      packageTypeId: reader.strOrNull('packageTypeId'),
      declaredValue: reader.intOrNull('declaredValue'),
      recipient: recipient == null
          ? null
          : BookingRecipient(
              name: recipient.strOr('name', ''),
              phone: recipient.strOr('phone', ''),
              email: recipient.strOrNull('email'),
              gender: PassengerGender.fromCode(recipient.strOrNull('gender')),
            ),
    );
    final photo = reader.objectOrNull('photo');
    final path = photo?.strOrNull('path');
    if (photo != null && path != null && File(path).existsSync()) {
      _photo.value = PhotoUploaded(path: path, id: photo.strOr('id', ''), url: photo.strOr('url', ''));
    }
  }

  void _persist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(persistDelay, _writeDraft);
  }

  Future<void> _writeDraft() async {
    final current = draft;
    final uploaded = photo;
    final isEmpty = current.kindId == null && current.name.isEmpty && current.recipient == null;
    if (isEmpty) {
      await SessionStorage.drafts.remove(DraftKeys.deliveryDraft);
      return;
    }
    await SessionStorage.drafts.write(DraftKeys.deliveryDraft, {
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'kindId': current.kindId,
      'name': current.name,
      'description': current.description,
      'sizeId': current.sizeId,
      'packageTypeId': current.packageTypeId,
      'declaredValue': current.declaredValue,
      'recipient': current.recipient?.toJson(),
      'photo': uploaded is PhotoUploaded ? {'path': uploaded.path, 'id': uploaded.id, 'url': uploaded.url} : null,
    });
  }

  Future<void> loadCatalog() async {
    if (catalogState is DeliveryCatalogReady) return;
    _catalog.value = const DeliveryCatalogLoading();
    try {
      final response = await _api.get(
        DeliveryEndpoints.catalog,
        suppressErrorToast: true,
        profile: RequestProfile.interactive,
      );
      _catalog.value = DeliveryCatalogReady(DeliveryCatalog.fromJson(response.dataMapOrEmpty));
    } catch (e) {
      log('loadCatalog failed: $e');
      _catalog.value = const DeliveryCatalogFailed();
    }
  }

  void selectKind(String id) {
    if (draft.kindId == id) return;
    _draft.value = draft.copyWith(kindId: id);
    _persist();
  }

  void setName(String value) {
    _draft.value = draft.copyWith(name: value);
    _persist();
  }

  void setDescription(String value) {
    _draft.value = draft.copyWith(description: value);
    _persist();
  }

  void selectSize(String id) {
    _draft.value = draft.copyWith(sizeId: id);
    _persist();
  }

  void selectPackageType(String id) {
    _draft.value = draft.copyWith(packageTypeId: id);
    _persist();
  }

  void setDeclaredValue(int? value) {
    _draft.value = draft.copyWith(declaredValue: () => value);
    _persist();
  }

  void selectTier(String id) {
    if (quote?.tierOf(id) == null) return;
    _draft.value = draft.copyWith(tierId: id);
  }

  void setRecipient(BookingRecipient recipient) {
    _draft.value = draft.copyWith(recipient: recipient);
    _recipientFailure.value = null;
    _persist();
  }

  void flagRecipientPhone(DeliveryFailure failure) => _recipientFailure.value = failure;

  void clearRecipientFailure() => _recipientFailure.value = null;

  Future<void> pickPhoto(PhotoSource source) async {
    if (photo.isBusy) return;
    final epoch = _photoEpoch.next();
    final before = photo;
    try {
      final path = await PackagePhotoService.pick(
        source,
        onPicked: () {
          if (_photoEpoch.isCurrent(epoch)) _photo.value = const PhotoPreparing();
        },
      );
      if (!_photoEpoch.isCurrent(epoch)) {
        await ImageCompressionService.discard(path);
        return;
      }
      if (path == null) return;
      await ImageCompressionService.discard(before.localPath);
      await _upload(path, epoch);
    } on PhotoException catch (e) {
      if (_photoEpoch.isCurrent(epoch)) _photo.value = PhotoFailed(failure: e.failure);
    } catch (e) {
      log('pickPhoto failed: $e');
      if (_photoEpoch.isCurrent(epoch)) _photo.value = const PhotoFailed(failure: DeliveryFailure.unreadablePhoto);
    }
  }

  Future<void> retryUpload() async {
    final path = photo.localPath;
    if (path == null || photo.isBusy) return;
    await _upload(path, _photoEpoch.next());
  }

  Future<void> removePhoto() async {
    _photoEpoch.next();
    final path = photo.localPath;
    _photo.value = const PhotoNone();
    await ImageCompressionService.discard(path);
    _persist();
  }

  Future<void> _upload(String path, int epoch) async {
    _photo.value = PhotoUploading(path: path, progress: 0);
    try {
      final ref = await _api.upload(
        DeliveryEndpoints.uploads,
        file: File(path),
        purpose: UploadPurposes.packagePhoto,
        suppressErrorToast: true,
        onProgress: (sent, total) {
          if (_photoEpoch.isCurrent(epoch) && total > 0) {
            _photo.value = PhotoUploading(path: path, progress: sent / total);
          }
        },
      );
      if (!_photoEpoch.isCurrent(epoch)) return;
      _photo.value = PhotoUploaded(path: path, id: ref.id, url: ref.url);
      _persist();
    } catch (e) {
      log('upload failed: $e');
      if (_photoEpoch.isCurrent(epoch)) _photo.value = PhotoFailed(failure: DeliveryFailure.of(e), path: path);
    }
  }

  Future<void> ensureQuote({bool force = false}) async {
    final catalog = this.catalog;
    if (catalog == null || !_ride.hasRoute || draft.kindId == null) return;
    final signature = _signatureOf(catalog);
    final current = quoteState;
    final isCurrent = _quoteSignature == signature;
    if (!force && isCurrent && current is QuoteLoading) return;
    if (!force && isCurrent && current is QuoteReady && !current.quote.isExpired) return;
    final epoch = _quoteEpoch.next();
    _quoteSignature = signature;
    _quote.value = const QuoteLoading();
    try {
      final response = await _api.post(DeliveryEndpoints.quote, data: _quoteBody(catalog), suppressErrorToast: true);
      if (!_quoteEpoch.isCurrent(epoch)) return;
      final quote = DeliveryQuote.fromJson(response.dataMapOrEmpty);
      _chooseTier(quote);
      _quote.value = QuoteReady(quote, signature: signature);
    } catch (e) {
      log('quote failed: $e');
      if (_quoteEpoch.isCurrent(epoch)) _quote.value = QuoteFailed(DeliveryFailure.of(e));
    }
  }

  Future<SubmitCheck> prepareSubmit() async {
    final catalog = this.catalog;
    final recipient = draft.recipient;
    if (catalog == null || recipient == null || !isItemComplete) return SubmitCheck.incomplete;
    final latest = quoteState;
    if (latest is! QuoteReady || !_isFresh(latest, catalog)) {
      final previousFare = selectedTier?.fare;
      await ensureQuote(force: true);
      final refreshed = selectedTier;
      if (refreshed == null) return SubmitCheck.priceUnavailable;
      if (refreshed.fare != previousFare) return SubmitCheck.priceRefreshed;
    }
    final current = quoteState;
    final tier = selectedTier;
    final sizeId = draft.effectiveSizeId(catalog);
    final typeId = draft.effectivePackageTypeId(catalog);
    final kindId = draft.kindId;
    if (current is! QuoteReady || tier == null || sizeId == null || typeId == null || kindId == null) {
      return SubmitCheck.incomplete;
    }
    _ride.setDeliveryBooking(
      DeliveryBooking(
        quoteId: current.quote.quoteId,
        tierId: tier.id,
        kindId: kindId,
        fare: tier.fare,
        item: BookingItem(
          name: draft.name.trim(),
          description: draft.description.trim(),
          sizeId: sizeId,
          packageTypeId: typeId,
          photoId: photo.uploadId,
          declaredValue: draft.declaredValue,
        ),
        recipient: recipient,
      ),
    );
    return SubmitCheck.ready;
  }

  bool _isFresh(QuoteReady ready, DeliveryCatalog catalog) =>
      ready.signature == _signatureOf(catalog) && !ready.quote.isExpired;

  void _chooseTier(DeliveryQuote quote) {
    final keepsChoice = quote.tierOf(draft.tierId) != null && quote.recommendedTier == _lastRecommendedTier;
    _lastRecommendedTier = quote.recommendedTier;
    if (keepsChoice) return;
    final preselected = quote.preselected;
    if (preselected != null) _draft.value = draft.copyWith(tierId: preselected.id);
  }

  String _signatureOf(DeliveryCatalog catalog) {
    final places = [_ride.pickup, ..._ride.stops, _ride.dropoff];
    return [
      draft.kindId,
      draft.effectiveSizeId(catalog),
      draft.effectivePackageTypeId(catalog),
      draft.declaredValue,
      for (final place in places) '${place?.placeId}@${place?.coordinates?.latitude},${place?.coordinates?.longitude}',
    ].join('|');
  }

  Map<String, dynamic> _quoteBody(DeliveryCatalog catalog) => {
    'pickup': _ride.pickup?.toJson(),
    'dropoff': _ride.dropoff?.toJson(),
    'stops': [for (final stop in _ride.stops) stop.toJson()],
    'kind': draft.kindId,
    'size': draft.effectiveSizeId(catalog),
    'packageType': draft.effectivePackageTypeId(catalog),
    'declaredValue': draft.declaredValue,
  };
}
