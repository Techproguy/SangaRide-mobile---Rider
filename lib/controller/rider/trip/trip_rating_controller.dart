import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';

class TripRatingController extends GetxController {
  static const String alreadyRatedCode = 'already_rated';

  final _api = Get.find<ApiService>();

  final Rx<RatingState> _state = Rx<RatingState>(const RatingEditing(DriverRating()));
  String? _tripId;
  int _epoch = 0;

  Rx<RatingState> get stateRx => _state;

  RatingState get state => _state.value;

  bool get isSubmitting => state is RatingSubmitting;

  @override
  void onClose() {
    _epoch++;
    super.onClose();
  }

  void open(String tripId, {bool isDelivery = false}) {
    _epoch++;
    _tripId = tripId;
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
    final epoch = ++_epoch;
    _state.value = RatingSubmitting(rating);
    try {
      await _api.post(AppEndpoints.tripRatingOf(id), data: rating.toJson(), suppressErrorToast: true);
    } catch (e) {
      log('rating failed: ${e is ApiException ? e.code : e.runtimeType}');
      final isDone = e is ApiException && e.statusCode == 409 && e.code == alreadyRatedCode;
      if (epoch != _epoch) return false;
      _state.value = isDone ? RatingSubmitted(rating) : RatingFailed(rating);
      return isDone;
    }
    if (epoch != _epoch) return false;
    _state.value = RatingSubmitted(rating);
    return true;
  }
}
