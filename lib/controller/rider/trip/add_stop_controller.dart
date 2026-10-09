import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class AddStopController extends GetxController {
  static const String quoteExpiredCode = 'quote_expired';

  final _api = Get.find<ApiService>();
  final _trip = Get.find<TripController>();

  final Rx<AddStopState> _state = Rx<AddStopState>(const AddStopDrafting([]));
  Mutation<Trip>? _mutation;
  String? _mutationSignature;
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

  @override
  void onClose() {
    _releaseMutation();
    super.onClose();
  }

  void open(String tripId) {
    _tripId = tripId;
    _epoch++;
    _releaseMutation();
    _state.value = const AddStopDrafting([]);
  }

  void reset() {
    _tripId = null;
    _epoch++;
    _releaseMutation();
    _state.value = const AddStopDrafting([]);
  }

  void _releaseMutation() {
    _mutation?.dispose();
    _mutation = null;
    _mutationSignature = null;
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
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return;
    }
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
      if (epoch == _epoch) _state.value = AddStopFailed(AddStopFailure.of(e), stops, serverMessage: _rejection(e));
    }
  }

  String? _rejection(Object error) =>
      error is ApiException && error.kind == ApiFailureKind.rejected && error.message.isNotEmpty ? error.message : null;

  Future<void> confirm() async {
    final current = state;
    final id = _tripId;
    if (current is! AddStopReviewing || current.isApplying || id == null) return;
    if (current.quote.isExpired) return requestQuote(isRefresh: true);
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return;
    }
    final epoch = ++_epoch;
    _state.value = current.applying();
    final stopsBefore = _trip.trip?.stops.length ?? 0;
    final mutation = _mutationFor(id, current, stopsBefore);
    final result = await mutation.start();
    if (epoch != _epoch) return;
    switch (result) {
      case MutationDone<Trip>(:final value):
        _releaseMutation();
        _trip.applyServerTrip(value);
        _trip.announce(TripNotice.fareUpdated);
        _state.value = AddStopApplied(value);
      case MutationRejected<Trip>(:final error):
        _releaseMutation();
        if (error.code == quoteExpiredCode) return requestQuote(isRefresh: true);
        _state.value = AddStopFailed(
          AddStopFailure.of(error),
          current.added,
          quote: current.quote,
          serverMessage: _rejection(error),
        );
      case MutationFailed<Trip>(:final error):
        _state.value = AddStopFailed(AddStopFailure.of(error), current.added, quote: current.quote);
      case MutationUnknown<Trip>():
        unawaited(_trip.pollNow());
        _state.value = AddStopFailed(AddStopFailure.unknown, current.added, quote: current.quote);
      default:
        break;
    }
  }

  Mutation<Trip> _mutationFor(String id, AddStopReviewing reviewing, int stopsBefore) {
    final signature = reviewing.quote.id;
    final existing = _mutation;
    if (existing != null && _mutationSignature == signature) return existing;
    existing?.dispose();
    _mutationSignature = signature;
    return _mutation = Mutation<Trip>(
      intent: 'trip-add-stops',
      run: (key) async {
        final response = await _api.post(
          AppEndpoints.liveTripStopsOf(id),
          data: {..._stopsBody(reviewing.added), 'quoteId': reviewing.quote.id},
          key: key,
          suppressErrorToast: true,
        );
        return Trip.fromJson(_dataOf(response.data));
      },
      reconcile: () async {
        final trip = await _trip.pollNow();
        if (trip == null) return const ReconciledPending();
        final applied = trip.stops.length >= stopsBefore + reviewing.added.length;
        return applied ? ReconciledDone(trip) : const ReconciledNotDone();
      },
    );
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

  Map<String, dynamic> _dataOf(dynamic body) => JsonReader.of(JsonReader.of(body).raw['data']).raw;
}
