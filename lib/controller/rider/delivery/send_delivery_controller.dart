import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/delivery_endpoints.dart';
import 'package:sanga_ride/core/services/image_compression_service.dart';
import 'package:sanga_ride/core/services/package_photo_service.dart';
import 'package:sanga_ride/model/models.dart';

enum SubmitCheck { ready, priceRefreshed, priceUnavailable, incomplete }

class SendDeliveryController extends GetxController {
  final _api = Get.find<ApiService>();
  final _ride = Get.find<RideRequestController>();

  final Rx<DeliveryCatalogState> _catalog = Rx<DeliveryCatalogState>(const DeliveryCatalogLoading());
  final Rx<DeliveryDraft> _draft = Rx<DeliveryDraft>(const DeliveryDraft());
  final Rx<PackagePhotoState> _photo = Rx<PackagePhotoState>(const PhotoNone());
  final Rx<DeliveryQuoteState> _quote = Rx<DeliveryQuoteState>(const QuoteIdle());
  final Rxn<DeliveryFailure> _recipientFailure = Rxn<DeliveryFailure>();
  int _photoEpoch = 0;
  int _quoteEpoch = 0;
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
    ImageCompressionService.discard(photo.localPath);
    super.onClose();
  }

  void begin() {
    _photoEpoch++;
    _quoteEpoch++;
    ImageCompressionService.discard(photo.localPath);
    _draft.value = const DeliveryDraft();
    _photo.value = const PhotoNone();
    _quote.value = const QuoteIdle();
    _recipientFailure.value = null;
    _quoteSignature = null;
    _lastRecommendedTier = null;
  }

  Future<void> loadCatalog() async {
    if (catalogState is DeliveryCatalogReady) return;
    _catalog.value = const DeliveryCatalogLoading();
    try {
      final response = await _api.get(DeliveryEndpoints.catalog, suppressErrorToast: true);
      _catalog.value = DeliveryCatalogReady(DeliveryCatalog.fromJson(_dataOf(response.data)));
    } catch (e) {
      log('loadCatalog failed: $e');
      _catalog.value = const DeliveryCatalogFailed();
    }
  }

  void selectKind(String id) {
    if (draft.kindId == id) return;
    _draft.value = draft.copyWith(kindId: id);
  }

  void setName(String value) => _draft.value = draft.copyWith(name: value);

  void setDescription(String value) => _draft.value = draft.copyWith(description: value);

  void selectSize(String id) => _draft.value = draft.copyWith(sizeId: id);

  void selectPackageType(String id) => _draft.value = draft.copyWith(packageTypeId: id);

  void setDeclaredValue(int? value) => _draft.value = draft.copyWith(declaredValue: () => value);

  void selectTier(String id) {
    if (quote?.tierOf(id) == null) return;
    _draft.value = draft.copyWith(tierId: id);
  }

  void setRecipient(BookingRecipient recipient) {
    _draft.value = draft.copyWith(recipient: recipient);
    _recipientFailure.value = null;
  }

  void flagRecipientPhone(DeliveryFailure failure) => _recipientFailure.value = failure;

  void clearRecipientFailure() => _recipientFailure.value = null;

  Future<void> pickPhoto(PhotoSource source) async {
    if (photo.isBusy) return;
    final epoch = ++_photoEpoch;
    final before = photo;
    try {
      final path = await PackagePhotoService.pick(
        source,
        onPicked: () {
          if (epoch == _photoEpoch) _photo.value = const PhotoPreparing();
        },
      );
      if (epoch != _photoEpoch) {
        await ImageCompressionService.discard(path);
        return;
      }
      if (path == null) return;
      await ImageCompressionService.discard(before.localPath);
      await _upload(path, epoch);
    } on PhotoException catch (e) {
      if (epoch == _photoEpoch) _photo.value = PhotoFailed(failure: e.failure);
    } catch (e) {
      log('pickPhoto failed: $e');
      if (epoch == _photoEpoch) _photo.value = const PhotoFailed(failure: DeliveryFailure.unreadablePhoto);
    }
  }

  Future<void> retryUpload() async {
    final path = photo.localPath;
    if (path == null || photo.isBusy) return;
    await _upload(path, ++_photoEpoch);
  }

  Future<void> removePhoto() async {
    _photoEpoch++;
    final path = photo.localPath;
    _photo.value = const PhotoNone();
    await ImageCompressionService.discard(path);
  }

  Future<void> _upload(String path, int epoch) async {
    _photo.value = PhotoUploading(path: path, progress: 0);
    try {
      final response = await _api.uploadFile(
        DeliveryEndpoints.uploads,
        file: File(path),
        fields: {'purpose': DeliveryRules.packagePhotoPurpose},
        suppressErrorToast: true,
        onSendProgress: (sent, total) {
          if (epoch == _photoEpoch && total > 0) _photo.value = PhotoUploading(path: path, progress: sent / total);
        },
      );
      if (epoch != _photoEpoch) return;
      final data = _dataOf(response.data);
      _photo.value = PhotoUploaded(path: path, id: data['id'] as String, url: data['url'] as String);
    } on ApiException catch (e) {
      log('upload failed: $e');
      if (epoch == _photoEpoch) _photo.value = PhotoFailed(failure: DeliveryFailure.fromCode(e.code), path: path);
    } catch (e) {
      log('upload failed: $e');
      if (epoch == _photoEpoch) _photo.value = PhotoFailed(failure: DeliveryFailure.connection, path: path);
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
    final epoch = ++_quoteEpoch;
    _quoteSignature = signature;
    _quote.value = const QuoteLoading();
    try {
      final response = await _api.post(DeliveryEndpoints.quote, data: _quoteBody(catalog), suppressErrorToast: true);
      if (epoch != _quoteEpoch) return;
      final quote = DeliveryQuote.fromJson(_dataOf(response.data));
      _chooseTier(quote);
      _quote.value = QuoteReady(quote, signature: signature);
    } on ApiException catch (e) {
      log('quote failed: $e');
      if (epoch == _quoteEpoch) _quote.value = QuoteFailed(DeliveryFailure.fromCode(e.code));
    } catch (e) {
      log('quote failed: $e');
      if (epoch == _quoteEpoch) _quote.value = const QuoteFailed(DeliveryFailure.connection);
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

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
