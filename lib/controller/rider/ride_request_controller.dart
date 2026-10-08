import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/booking_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/booking.dart';

class RideRequestController extends GetxController {
  static const int maxStops = Trip.maxStops;

  final _api = Get.find<ApiService>();
  int _estimateRequest = 0;

  final Rxn<Place> _pickup = Rxn<Place>();
  final Rxn<Place> _dropoff = Rxn<Place>();
  final RxList<Place> _stops = <Place>[].obs;
  final Rx<TripType> _tripType = TripType.oneWay.obs;
  final RxList<RideOption> _options = <RideOption>[].obs;
  final RxnString _optionId = RxnString();
  final Rx<RidePreferences> _preferences = const RidePreferences().obs;
  final Rxn<PricingOption> _pricing = Rxn<PricingOption>();
  final Rxn<FareEstimate> _estimate = Rxn<FareEstimate>();
  final Rx<RideTiming> _timing = RideTiming.now.obs;
  final Rxn<DateTime> _scheduledAt = Rxn<DateTime>();
  final RxBool _isLoadingOptions = false.obs;
  final RxBool _optionsFailed = false.obs;
  final RxBool _isEstimating = false.obs;
  final RxBool _isRestoring = false.obs;
  final Rxn<RepeatRule> _repeatRule = Rxn<RepeatRule>();
  final Rxn<DateTime> _returnAt = Rxn<DateTime>();
  final RxInt _hours = BookingRules.defaultHours.obs;
  final RxBool _staysWithRider = true.obs;
  final RxBool _isScheduling = false.obs;
  final Rx<BookingCatalogState> _catalog = Rx<BookingCatalogState>(const CatalogLoading());

  Place? get pickup => _pickup.value;

  Place? get dropoff => _dropoff.value;

  List<Place> get stops => _stops;

  TripType get tripType => _tripType.value;

  List<RideOption> get options => _options;

  RideOption? get option => _options.firstWhereOrNull((option) => option.id == _optionId.value);

  RidePreferences get preferences => _preferences.value;

  PricingOption? get pricing => _pricing.value;

  FareEstimate? get estimate => _estimate.value;

  RideTiming get timing => _timing.value;

  DateTime? get scheduledAt => _scheduledAt.value;

  bool get isLoadingOptions => _isLoadingOptions.value;

  bool get optionsFailed => _optionsFailed.value;

  bool get isEstimating => _isEstimating.value;

  bool get isRestoring => _isRestoring.value;

  RepeatRule? get repeatRule => _repeatRule.value;

  DateTime? get returnAt => _returnAt.value;

  int get hours => _hours.value;

  bool get staysWithRider => _staysWithRider.value;

  bool get isScheduling => _isScheduling.value;

  BookingCatalogState get catalog => _catalog.value;

  BookingCatalog? get readyCatalog => switch (catalog) {
    CatalogReady(:final catalog) => catalog,
    CatalogLoading() || CatalogFailed() => null,
  };

  String rateLabel(RideOption option) {
    final hourly = tripType == TripType.hourly ? readyCatalog?.hourly.rates[option.category] : null;
    return hourly == null ? SangaMoney.perKm(option.pricePerKm) : SangaMoney.perHour(hourly);
  }

  City? cityOf(Place? place) {
    final cities = readyCatalog?.intercity.cities;
    return cities == null ? null : City.nearest(cities, place?.coordinates);
  }

  City? get fromCity => cityOf(pickup);

  City? get toCity => cityOf(dropoff);

  IntercityIssue? get intercityIssue {
    if (readyCatalog == null) return null;
    final from = fromCity;
    final to = toCity;
    if (from == null) return IntercityIssue.unsupportedPickup;
    if (to == null) return IntercityIssue.unsupportedDropoff;
    if (from.id == to.id) return IntercityIssue.sameCity;
    return null;
  }

  num? get hourlyRate => readyCatalog?.hourly.rateFor(option?.category);

  bool get isScheduledBooking => timing.isScheduled || tripType.isAlwaysScheduled;

  DateTime? get departureAt => timing == RideTiming.now ? DateTime.now() : scheduledAt;

  DateTime? get earliestReturn => departureAt?.add(BookingRules.returnGap);

  bool get isReadyToReview => switch (tripType) {
    TripType.oneWay => timing != RideTiming.later || scheduledAt != null,
    TripType.roundTrip => returnAt != null && (timing != RideTiming.later || scheduledAt != null),
    TripType.hourly => timing != RideTiming.later || scheduledAt != null,
    TripType.intercity => scheduledAt != null && intercityIssue == null,
  };

  bool get hasRoute => pickup != null && dropoff != null;

  bool get canAddStop => hasRoute && stops.length < maxStops;

  List<LatLng> get routePoints => [
    for (final place in [pickup, ...stops, dropoff]) ?place?.coordinates,
  ];

  num? get price => pricing == null ? null : estimate?.pricing[pricing];

  void start({Place? pickup, Place? dropoff, RideCategory? category}) {
    _pickup.value = pickup;
    _dropoff.value = dropoff;
    _stops.clear();
    _tripType.value = TripType.oneWay;
    _preferences.value = const RidePreferences();
    _pricing.value = null;
    _estimate.value = null;
    _timing.value = RideTiming.now;
    _scheduledAt.value = null;
    _repeatRule.value = null;
    _returnAt.value = null;
    _hours.value = BookingRules.defaultHours;
    _staysWithRider.value = true;
    _optionId.value = category == null ? null : _options.firstWhereOrNull((o) => o.category == category)?.id;
    _preferredCategory = category;
  }

  RideCategory? _preferredCategory;

  Future<bool> restoreRoute({
    required Place pickup,
    required List<Place> stops,
    required Place dropoff,
    required RideCategory category,
  }) async {
    if (isRestoring) return false;
    _isRestoring.value = true;
    try {
      start(pickup: pickup, dropoff: dropoff, category: category);
      _stops.assignAll(stops);
      await loadOptions();
      if (option == null || !await loadEstimate()) return false;
      selectPricing(PricingOption.standard);
      return true;
    } finally {
      _isRestoring.value = false;
    }
  }

  void setPickup(Place place) {
    _pickup.value = place;
    _clearQuote();
  }

  void setDropoff(Place place) {
    _dropoff.value = place;
    _clearQuote();
  }

  String? applyRouteEdit(RouteEdit edit, Place place) {
    final others = [
      if (edit.point != RoutePoint.pickup) pickup,
      for (final (index, stop) in stops.indexed)
        if (edit.point != RoutePoint.stop || edit.stopIndex != index) stop,
      if (edit.point != RoutePoint.dropoff) dropoff,
    ].whereType<Place>();
    final clash = others.where((other) => other.isSameAs(place)).firstOrNull;
    if (clash != null) {
      final isEnds = edit.point != RoutePoint.stop && (identical(clash, pickup) || identical(clash, dropoff));
      return isEnds ? 'Your pickup and drop off can’t be the same place.' : 'That place is already on your route.';
    }
    switch (edit.point) {
      case RoutePoint.pickup:
        setPickup(place);
      case RoutePoint.dropoff:
        setDropoff(place);
      case RoutePoint.stop:
        final index = edit.stopIndex;
        if (index == null) {
          if (stops.length >= maxStops) return 'You can add up to $maxStops stops.';
          _stops.add(place);
        } else {
          _stops[index] = place;
        }
        _clearQuote();
    }
    return null;
  }

  void removeStopAt(int index) {
    _stops.removeAt(index);
    _clearQuote();
  }

  void setTripType(TripType type) {
    if (type == tripType) return;
    final wasAlwaysScheduled = tripType.isAlwaysScheduled;
    _tripType.value = type;
    if (wasAlwaysScheduled || (!type.allowsRepeat && timing == RideTiming.repeat)) setTiming(RideTiming.now);
    if (!type.needsReturn) _returnAt.value = null;
    _clearQuote();
  }

  void setHours(int value) {
    final limits = readyCatalog?.hourly;
    final clamped = limits == null ? value : value.clamp(limits.minHours, limits.maxHours);
    if (clamped == hours) return;
    _hours.value = clamped;
    _clearQuote();
  }

  void setStaysWithRider(bool value) {
    if (value == staysWithRider) return;
    _staysWithRider.value = value;
    _clearQuote();
  }

  void setReturnAt(DateTime? value) => _returnAt.value = value;

  void setRepeatRule(RepeatRule? rule) {
    _repeatRule.value = rule;
    if (rule != null) setTiming(RideTiming.repeat);
  }

  void confirmIntercityDeparture(DateTime departure) {
    _timing.value = RideTiming.later;
    _scheduledAt.value = departure;
    _repeatRule.value = null;
  }

  void selectOption(RideOption option) {
    if (option.id == _optionId.value) return;
    _optionId.value = option.id;
    _clearQuote();
  }

  void _clearQuote() {
    _estimateRequest++;
    _isEstimating.value = false;
    _estimate.value = null;
    _pricing.value = null;
  }

  void updatePreferences(RidePreferences preferences) {
    if (preferences == this.preferences) return;
    _preferences.value = preferences;
    _clearQuote();
  }

  void selectPricing(PricingOption option) => _pricing.value = option;

  void setTiming(RideTiming timing, {DateTime? scheduledAt}) {
    _timing.value = timing;
    _scheduledAt.value = timing == RideTiming.later ? scheduledAt : null;
    if (timing != RideTiming.repeat) _repeatRule.value = null;
    final earliest = earliestReturn;
    if (earliest != null && (returnAt?.isBefore(earliest) ?? false)) _returnAt.value = null;
  }

  Future<void> loadCatalog() async {
    if (catalog is CatalogReady) return;
    _catalog.value = const CatalogLoading();
    try {
      final responses = await Future.wait([_api.get(BookingEndpoints.hourlyRates), _api.get(BookingEndpoints.cities)]);
      _catalog.value = CatalogReady(
        BookingCatalog(
          hourly: HourlyCatalog.fromJson(_dataOf(responses[0].data)),
          intercity: IntercityCatalog.fromJson(_dataOf(responses[1].data)),
        ),
      );
    } catch (e) {
      log('loadCatalog failed: $e');
      _catalog.value = const CatalogFailed();
    }
  }

  Map<String, dynamic> get bookingJson => {
    'tripType': tripType.name,
    'timing': timing.name,
    if (scheduledAt case final at?) 'scheduledAt': at.toUtc().toIso8601String(),
    if (repeatRule case final rule?) 'repeat': rule.toJson(),
    if (tripType == TripType.hourly) ...{'hours': hours, 'stayWithMe': staysWithRider},
    if (tripType == TripType.intercity) ...{'fromCityId': fromCity?.id, 'toCityId': toCity?.id},
    if (returnAt case final at? when tripType.needsReturn) 'returnAt': at.toUtc().toIso8601String(),
  };

  Map<String, dynamic>? requestPayload() {
    final pickup = this.pickup;
    final dropoff = this.dropoff;
    final option = this.option;
    final pricing = this.pricing;
    final price = this.price;
    if (pickup == null || dropoff == null || option == null || pricing == null || price == null) return null;
    return {
      'optionId': option.id,
      'pickup': pickup.toJson(),
      'stops': [for (final stop in stops) stop.toJson()],
      'dropoff': dropoff.toJson(),
      'preferences': preferences.toJson(),
      'rideFor': Get.find<RideForController>().rideFor.toJson(),
      'pricingMode': pricing.name,
      'proposedFare': price.round(),
      ...bookingJson,
    };
  }

  Future<ScheduleOutcome?> scheduleBooking() async {
    if (isScheduling || !isScheduledBooking) return null;
    final payload = requestPayload();
    if (payload == null) return const ScheduleRejected(BookingProblem.unknown);
    _isScheduling.value = true;
    try {
      final response = await _api.post(BookingEndpoints.scheduledRides, data: payload, suppressErrorToast: true);
      return ScheduleSucceeded(ScheduledBooking.fromJson(_dataOf(response.data)));
    } on ApiException catch (e) {
      log('scheduleBooking failed: $e');
      return ScheduleRejected(BookingProblem.fromCode(e.code));
    } catch (e) {
      log('scheduleBooking failed: $e');
      return const ScheduleRejected(BookingProblem.unknown);
    } finally {
      _isScheduling.value = false;
    }
  }

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);

  Future<void> loadOptions() async {
    if (_options.isNotEmpty) return;
    _optionsFailed.value = false;
    _isLoadingOptions.value = true;
    try {
      final response = await _api.get(MockEndpoints.rideOptions);
      final data = response.data['data'] as List;
      _options.assignAll(data.map((json) => RideOption.fromJson(Map<String, dynamic>.from(json as Map))));
      final preferred = _preferredCategory;
      if (preferred != null && _optionId.value == null) {
        _optionId.value = _options.firstWhereOrNull((o) => o.category == preferred)?.id;
      }
    } catch (e) {
      log('loadOptions failed: $e');
      _optionsFailed.value = true;
    } finally {
      _isLoadingOptions.value = false;
    }
  }

  Future<bool> loadEstimate() async {
    final pickup = this.pickup;
    final dropoff = this.dropoff;
    final option = this.option;
    if (pickup == null || dropoff == null || option == null) return false;
    final request = ++_estimateRequest;
    _isEstimating.value = true;
    try {
      final response = await _api.post(
        MockEndpoints.rideEstimate,
        data: {
          'pickup': pickup.toJson(),
          'dropoff': dropoff.toJson(),
          'stops': [for (final stop in stops) stop.toJson()],
          'optionId': option.id,
          'pricePerKm': option.pricePerKm,
          'preferences': preferences.toJson(),
          ...bookingJson,
        },
      );
      if (request != _estimateRequest) return false;
      _estimate.value = FareEstimate.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
      return true;
    } catch (e) {
      log('loadEstimate failed: $e');
      return false;
    } finally {
      if (request == _estimateRequest) _isEstimating.value = false;
    }
  }
}
