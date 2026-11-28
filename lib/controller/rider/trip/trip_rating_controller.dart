import 'dart:async';
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
  final RxList<RatingTag> _tags = <RatingTag>[].obs;
  String? _tripId;
  IdempotencyKey? _key;
  String? _keyedRequest;
  final Epoch _epoch = Epoch();

  Rx<RatingState> get stateRx => _state;

  RatingState get state => _state.value;

  bool get isSubmitting => state is RatingSubmitting;

  List<RatingTag> get tags => _tags;

  List<RatingTag> tagsFor(int stars) => [
    for (final tag in _tags)
      if (tag.isOfferedFor(stars)) tag,
  ];

  @override
  void onClose() {
    _epoch.next();
    super.onClose();
  }

  Future<void> loadTags() async {
    try {
      final response = await _api.get(AppEndpoints.ratingTags, suppressErrorToast: true);
      final tags = JsonReader.of({'tags': (response.data as Map)['data']}).listOf('tags', RatingTag.fromReader);
      _tags.assignAll(tags);
    } catch (e) {
      log('rating tags failed: $e');
    }
  }

  void open(String tripId) {
    unawaited(loadTags());
    if (_tripId == tripId && state is! RatingSubmitted) return;
    _epoch.next();
    _tripId = tripId;
    _state.value = const RatingEditing(DriverRating());
  }

  void setStars(int stars) {
    if (isSubmitting || state is RatingSubmitted) return;
    _state.value = RatingEditing(state.rating.withStars(stars, available: tagsFor(stars)));
  }

  void toggleTag(RatingTag tag) {
    if (isSubmitting || state is RatingSubmitted || !tagsFor(state.rating.stars).contains(tag)) return;
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
    final body = rating.toJson();
    try {
      await _api.post(AppEndpoints.tripRatingOf(id), data: body, key: _keyFor('$id $body'), suppressErrorToast: true);
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

  IdempotencyKey _keyFor(String request) {
    if (request != _keyedRequest) {
      _keyedRequest = request;
      _key = IdempotencyKey.newFor(IdempotencyIntent.tripRating);
    }
    return _key!;
  }
}
