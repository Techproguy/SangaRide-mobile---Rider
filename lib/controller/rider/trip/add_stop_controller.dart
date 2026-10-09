import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class AddStopController extends GetxController {
  static const String quoteExpiredCode = 'quote_expired';

  final _api = Get.find<ApiService>();
  final _trip = Get.find<TripController>();

  final Rx<AddStopState> _state = Rx<AddStopState>(const AddStopDrafting([]));
  String? _tripId;
  int _epoch = 0;

  Rx<AddStopState> get stateRx => _state;

  AddStopState get state => _state.value;

  List<Place> get added => switch (state) {
    AddStopDrafting(:final added) ||
    AddStopPlacing(:final added) ||
    AddStopQuoting(:final added) ||
    AddStopReviewing(:final added) ||
    AddStopFailed(:final added) => added,
    AddStopApplied() => const [],
  };

  bool get isBusy => switch (state) {
    AddStopQuoting() => true,
    AddStopReviewing(:final isApplying) => isApplying,
    _ => false,
  };

  int slotsLeft(Trip trip) => RideRequestController.maxStops - trip.stops.length - added.length;

  void open(String tripId) {
    _tripId = tripId;
    _epoch++;
    _state.value = const AddStopDrafting([]);
  }

  void reset() {
    _tripId = null;
    _epoch++;
    _state.value = const AddStopDrafting([]);
  }

  String? validate(Place place, Trip trip) {
    if (place.coordinates == null) return 'We couldn’t place that stop. Try another one.';
    if (slotsLeft(trip) <= 0) return 'You can add up to ${RideRequestController.maxStops} stops.';
    if (trip.pickup.toPlace().isSameAs(place)) return 'Your stop can’t be the same as your pickup.';
    if (trip.dropoff.toPlace().isSameAs(place)) return 'Your stop can’t be the same as your drop off.';
    final taken = [for (final stop in trip.stops) stop.toPlace(), ...added];
    if (taken.any((stop) => stop.isSameAs(place))) return 'That place is already on your trip.';
    return null;
  }

  void choose(Place place) {
    if (state is! AddStopDrafting) return;
    _state.value = AddStopPlacing(added, place);
  }

  void confirmPlace() {
    final current = state;
    if (current is! AddStopPlacing) return;
    _state.value = AddStopDrafting([...current.added, current.place]);
  }

  void cancelPlace() {
    if (state is AddStopPlacing) _state.value = AddStopDrafting(added);
  }

  void removeAt(int index) {
    final current = state;
    if (current is! AddStopDrafting || index < 0 || index >= current.added.length) return;
    _state.value = AddStopDrafting([...current.added]..removeAt(index));
  }

  void backToDrafting() {
    if (state is AddStopReviewing && !isBusy) _state.value = AddStopDrafting(added);
  }

  Future<void> requestQuote({bool isRefresh = false}) async {
    final id = _tripId;
    final stops = added;
    if (id == null || stops.isEmpty || isBusy) return;
    final epoch = ++_epoch;
    _state.value = AddStopQuoting(stops);
    try {
      final response = await _api.post(
        AppEndpoints.liveTripStopsQuoteOf(id),
        data: _stopsBody(stops),
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return;
      final quote = StopQuote.fromJson(_dataOf(response.data));
      _state.value = AddStopReviewing(stops, quote, isRefreshed: isRefresh);
    } catch (e) {
      log('stop quote failed: $e');
      if (epoch == _epoch) _state.value = AddStopFailed(_failureOf(e), stops);
    }
  }

  Future<void> confirm() async {
    final current = state;
    final id = _tripId;
    if (current is! AddStopReviewing || current.isApplying || id == null) return;
    if (current.quote.isExpired) return requestQuote(isRefresh: true);
    final epoch = ++_epoch;
    _state.value = current.applying();
    try {
      final response = await _api.post(
        AppEndpoints.liveTripStopsOf(id),
        data: {..._stopsBody(current.added), 'quoteId': current.quote.id},
        suppressErrorToast: true,
      );
      final trip = Trip.fromJson(_dataOf(response.data));
      _trip.applyServerTrip(trip);
      _trip.announce(TripNotice.fareUpdated);
      if (epoch == _epoch) _state.value = AddStopApplied(trip);
    } catch (e) {
      log('add stops failed: $e');
      if (epoch != _epoch) return;
      if (e is ApiException && e.code == quoteExpiredCode) return requestQuote(isRefresh: true);
      _state.value = AddStopFailed(_failureOf(e), current.added, quote: current.quote);
    }
  }

  bool resolveFailure({required bool isPrimary}) {
    final current = state;
    if (current is! AddStopFailed) return false;
    switch (current.reason.resolution) {
      case StopResolution.leave:
        return true;
      case StopResolution.restart:
        if (!isPrimary) return true;
        _state.value = const AddStopDrafting([]);
        return false;
      case StopResolution.retry:
        if (isPrimary) {
          _retry(current);
        } else {
          _state.value = current.quote == null
              ? AddStopDrafting(current.added)
              : AddStopReviewing(current.added, current.quote!);
        }
        return false;
    }
  }

  void _retry(AddStopFailed failed) {
    final quote = failed.quote;
    if (quote == null) {
      _state.value = AddStopDrafting(failed.added);
      unawaited(requestQuote());
    } else {
      _state.value = AddStopReviewing(failed.added, quote);
      unawaited(confirm());
    }
  }

  Map<String, dynamic> _stopsBody(List<Place> stops) => {
    'stops': [for (final stop in stops) stop.toJson()],
  };

  AddStopFailure _failureOf(Object error) => AddStopFailure.fromCode(error is ApiException ? error.code : null);

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
