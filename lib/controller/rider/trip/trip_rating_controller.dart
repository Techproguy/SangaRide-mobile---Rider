import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class TripRatingController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<RatingState> _state = Rx<RatingState>(const RatingEditing(DriverRating()));
  String? _tripId;
  IdempotencyKey? _key;
  final Epoch _epoch = Epoch();

  Rx<RatingState> get stateRx => _state;

  RatingState get state => _state.value;

  bool get isSubmitting => state is RatingSubmitting;

  @override
  void onClose() {
    _epoch.next();
    super.onClose();
  }

  void open(String tripId, {bool isDelivery = false}) {
    final isSame = _tripId == tripId && state.rating.isDelivery == isDelivery;
    if (isSame && state is! RatingSubmitted) return;
    _epoch.next();
    _tripId = tripId;
    _key = null;
    _state.value = RatingEditing(DriverRating(isDelivery: isDelivery));
  }

  void setStars(int stars) {
    if (isSubmitting || state is RatingSubmitted) return;
    _state.value = RatingEditing(state.rating.withStars(stars));
  }

  void toggleTag(RatingTag tag) {
    if (isSubmitting || state is RatingSubmitted || !state.rating.availableTags.contains(tag)) return;
    _state.value = RatingEditing(state.rating.toggled(tag));
  }

  void setComment(String comment) {
    if (isSubmitting || state is RatingSubmitted) return;
    _state.value = RatingEditing(state.rating.withComment(comment));
  }

  Future<bool> submit() async {
    final id = _tripId;
    final rating = state.rating;
    if (id == null || isSubmitting || state is RatingSubmitted || !rating.hasStars) return false;
    final epoch = _epoch.next();
    _state.value = RatingSubmitting(rating);
    try {
      await _api.post(
        AppEndpoints.tripRatingOf(id),
        data: rating.toJson(),
        key: _key ??= IdempotencyKey.newFor(IdempotencyIntent.tripRating),
        suppressErrorToast: true,
      );
    } catch (e) {
      log('rating failed: ${e is ApiException ? e.code : e.runtimeType}');
      final isDone = e is ApiException && e.statusCode == 409 && e.code == ServerCode.alreadyRated;
      if (!_epoch.isCurrent(epoch)) return false;
      _state.value = isDone ? RatingSubmitted(rating) : RatingFailed(rating);
      return isDone;
    }
    if (!_epoch.isCurrent(epoch)) return false;
    _state.value = RatingSubmitted(rating);
    return true;
  }
}
