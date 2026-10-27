import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class ExtendTripController extends GetxController {
  final _api = Get.find<ApiService>();
  final _trip = Get.find<TripController>();

  final RxMap<int, ExtendQuote> quotes = <int, ExtendQuote>{}.obs;
  final RxSet<int> quoting = <int>{}.obs;
  final RxSet<int> unavailable = <int>{}.obs;
  final Rxn<int> selected = Rxn<int>();
  final RxBool isCustom = false.obs;
  final RxInt customMinutes = ExtendOptions.customStartMinutes.obs;
  final RxBool isApplying = false.obs;

  String? _tripId;
  IdempotencyKey? _key;
  int? _keyMinutes;

  ExtendQuote? get selectedQuote {
    final minutes = selected.value;
    return minutes == null ? null : quotes[minutes];
  }

  bool get canConfirm => selectedQuote != null && !isApplying.value;

  bool get hasNoPrices => quoting.isEmpty && quotes.isEmpty && unavailable.isNotEmpty;

  void open(String tripId) {
    _tripId = tripId;
    quotes.clear();
    quoting.clear();
    unavailable.clear();
    selected.value = null;
    isCustom.value = false;
    customMinutes.value = ExtendOptions.customStartMinutes;
    isApplying.value = false;
    _key = null;
    _keyMinutes = null;
    for (final minutes in ExtendOptions.presetMinutes) {
      unawaited(_quote(minutes));
    }
  }

  void retry() {
    for (final minutes in ExtendOptions.presetMinutes) {
      if (!quotes.containsKey(minutes)) unawaited(_quote(minutes));
    }
  }

  void selectPreset(int minutes) {
    isCustom.value = false;
    selected.value = minutes;
  }

  void selectCustom() {
    isCustom.value = true;
    setCustom(customMinutes.value);
  }

  void setCustom(int minutes) {
    customMinutes.value = minutes;
    if (isCustom.value) selected.value = minutes;
    if (!quotes.containsKey(minutes)) unawaited(_quote(minutes));
  }

  Future<void> _quote(int minutes) async {
    final id = _tripId;
    if (id == null || quoting.contains(minutes)) return;
    quoting.add(minutes);
    unavailable.remove(minutes);
    try {
      final response = await _api.post(
        AppEndpoints.liveTripExtendQuoteOf(id),
        data: {'minutes': minutes},
        suppressErrorToast: true,
      );
      if (_tripId != id) return;
      quotes[minutes] = ExtendQuote.fromJson(minutes, response.dataMapOrEmpty);
    } catch (e) {
      log('extend quote for $minutes minutes failed: $e');
      if (_tripId == id) unavailable.add(minutes);
    } finally {
      quoting.remove(minutes);
    }
  }

  Future<bool> confirm() async {
    final id = _tripId;
    final quote = selectedQuote;
    if (id == null || quote == null || isApplying.value) return false;
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return false;
    }
    isApplying.value = true;
    try {
      if (_keyMinutes != quote.minutes) {
        _keyMinutes = quote.minutes;
        _key = IdempotencyKey.newFor(IdempotencyIntent.tripExtend);
      }
      final response = await _api.post(
        AppEndpoints.liveTripExtendOf(id),
        data: {'minutes': quote.minutes, 'quoteId': ?quote.id},
        key: _key,
        suppressErrorToast: true,
      );
      final body = response.dataMapOrEmpty;
      final trip = Trip.isRideShape(body) ? Trip.fromJson(body) : await _trip.loadLatest();
      _trip.applyServerTrip(trip);
      _trip.announce(TripNotice.fareUpdated);
      return true;
    } catch (e) {
      log('extend failed: $e');
      LiveProblem.toast(e);
      if (e is ApiException && e.kind == ApiFailureKind.rejected) {
        quotes.remove(quote.minutes);
        _keyMinutes = null;
        unawaited(_quote(quote.minutes));
      }
      return false;
    } finally {
      isApplying.value = false;
    }
  }
}
