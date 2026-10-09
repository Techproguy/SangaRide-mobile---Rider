import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/booking_endpoints.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

part 'ride_request_payload.dart';
part 'ride_request_route.dart';

class RideRequestController extends GetxController {
  static const int maxStops = Trip.maxStops;
  static const Duration catalogLifetime = Duration(minutes: 10);

  final _api = Get.find<ApiService>();
  final _estimateEpoch = Epoch();
  StreamSubscription<void>? _resumeSubscription;
  DateTime? _optionsLoadedAt;
  DateTime? _catalogLoadedAt;
  Mutation<ScheduledBooking>? _scheduleMutation;
  String? _scheduleSignature;

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
  final Rxn<RideLoadProblem> _optionsProblem = Rxn<RideLoadProblem>();
  final RxBool _isEstimating = false.obs;
  final Rxn<RideLoadProblem> _estimateProblem = Rxn<RideLoadProblem>();
  final RxBool _isRestoring = false.obs;
  final Rxn<RepeatRule> _repeatRule = Rxn<RepeatRule>();
  final Rxn<DateTime> _returnAt = Rxn<DateTime>();
  final RxInt _hours = BookingRules.defaultHours.obs;
  final RxBool _staysWithRider = true.obs;
  final RxBool _isScheduling = false.obs;
  final Rx<BookingCatalogState> _catalog = Rx<BookingCatalogState>(const CatalogLoading());
  final Rxn<AirportBooking> _airport = Rxn<AirportBooking>();
  final Rxn<DeliveryBooking> _delivery = Rxn<DeliveryBooking>();
  final Rxn<num> _knownMeetGreetFee = Rxn<num>();

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

  bool get optionsFailed => _optionsProblem.value != null;

  RideLoadProblem? get optionsProblem => _optionsProblem.value;

  bool get isEstimating => _isEstimating.value;

  RideLoadProblem? get estimateProblem => _estimateProblem.value;

  bool get isRestoring => _isRestoring.value;

  RepeatRule? get repeatRule => _repeatRule.value;

  DateTime? get returnAt => _returnAt.value;

  int get hours => _hours.value;

  bool get staysWithRider => _staysWithRider.value;

  bool get isScheduling => _isScheduling.value;

  BookingCatalogState get catalog => _catalog.value;

  AirportBooking? get airportBooking => _airport.value;

  DeliveryBooking? get deliveryBooking => _delivery.value;

  num? get meetGreetFee => estimate?.meetGreetFee ?? _knownMeetGreetFee.value;

  bool fitsGroup(RideOption option) {
    final booking = airportBooking;
    return tripType != TripType.airport || booking == null || option.maxSeats >= booking.passengers;
  }

  BookingCatalog? get readyCatalog => switch (catalog) {
    CatalogReady(:final catalog) => catalog,
    CatalogLoading() || CatalogFailed() => null,
  };

  BookingRules get rules => readyCatalog?.rules ?? BookingRules.fallback;

  @override
  void onInit() {
    super.onInit();
    _resumeSubscription = AppLifecycle.instance.onResume.listen((_) => _expireCatalogs());
  }

  @override
  void onClose() {
    _resumeSubscription?.cancel();
    _scheduleMutation?.dispose();
    super.onClose();
  }

  void _expireCatalogs() {
    _optionsLoadedAt = null;
    _catalogLoadedAt = null;
  }

  bool _isFresh(DateTime? loadedAt) => loadedAt != null && DateTime.now().difference(loadedAt) < catalogLifetime;

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

  DateTime? get departureAt => timing == RideTiming.now ? BookingClock.now() : scheduledAt;

  DateTime? get earliestReturn => departureAt?.add(rules.returnGap);

  bool get isReadyToReview => switch (tripType) {
    TripType.oneWay => timing != RideTiming.later || scheduledAt != null,
    TripType.roundTrip => returnAt != null && (timing != RideTiming.later || scheduledAt != null),
    TripType.hourly => timing != RideTiming.later || scheduledAt != null,
    TripType.intercity => scheduledAt != null && intercityIssue == null,
    TripType.airport => airportBooking != null,
    TripType.delivery => deliveryBooking != null,
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
    _airport.value = null;
    _delivery.value = null;
    _knownMeetGreetFee.value = null;
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

  void setTripType(TripType type) {
    if (type == tripType) return;
    final wasAlwaysScheduled = tripType.isAlwaysScheduled;
    _tripType.value = type;
    if (wasAlwaysScheduled || (!type.allowsRepeat && timing == RideTiming.repeat)) setTiming(RideTiming.now);
    if (!type.needsReturn) _returnAt.value = null;
    _clearQuote();
  }

  void setAirportBooking(AirportBooking booking) {
    final previous = airportBooking;
    _airport.value = booking;
    if (previous == null || jsonEncode(previous.toJson()) != jsonEncode(booking.toJson())) _clearQuote();
  }

  void setDeliveryBooking(DeliveryBooking booking) => _delivery.value = booking;

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
    _estimateEpoch.next();
    _isEstimating.value = false;
    _estimate.value = null;
    _estimateProblem.value = null;
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

  Future<void> loadCatalog({bool force = false}) async {
    if (catalog is CatalogReady && !force && _isFresh(_catalogLoadedAt)) return;
    if (catalog is! CatalogReady) _catalog.value = const CatalogLoading();
    try {
      final responses = await Future.wait([
        _api.get(BookingEndpoints.hourlyRates),
        _api.get(BookingEndpoints.cities),
        _api.get(BookingEndpoints.rules),
      ]);
      _catalog.value = CatalogReady(
        BookingCatalog(
          hourly: HourlyCatalog.fromJson(responses[0].dataMap),
          intercity: IntercityCatalog.fromJson(responses[1].dataMap),
          rules: BookingRules.fromJson(responses[2].dataMap),
        ),
      );
      _catalogLoadedAt = DateTime.now();
    } catch (e) {
      log('loadCatalog failed: $e');
      if (catalog is! CatalogReady) _catalog.value = CatalogFailed(RideLoadProblem.of(e));
    }
  }

  Future<void> loadOptions({bool force = false}) async {
    if (_options.isNotEmpty && !force && _isFresh(_optionsLoadedAt)) return;
    if (_isLoadingOptions.value) return;
    _optionsProblem.value = null;
    _isLoadingOptions.value = true;
    try {
      final response = await _api.get(AppEndpoints.rideOptions, suppressErrorToast: true);
      final loaded = JsonReader.of({'options': (response.data as Map)['data']}).listOf('options', RideOption.fromJson);
      _options.assignAll(loaded);
      _optionsLoadedAt = DateTime.now();
      final preferred = _preferredCategory;
      if (preferred != null && _optionId.value == null) {
        _optionId.value = _options.firstWhereOrNull((o) => o.category == preferred)?.id;
      }
      if (_optionId.value != null && _options.every((option) => option.id != _optionId.value)) {
        _optionId.value = null;
        _clearQuote();
      }
    } catch (e) {
      log('loadOptions failed: $e');
      if (_options.isEmpty) _optionsProblem.value = RideLoadProblem.of(e);
    } finally {
      _isLoadingOptions.value = false;
    }
  }

  Future<bool> loadEstimate() async {
    final pickup = this.pickup;
    final dropoff = this.dropoff;
    final option = this.option;
    if (pickup == null || dropoff == null || option == null) return false;
    final request = _estimateEpoch.next();
    _isEstimating.value = true;
    _estimateProblem.value = null;
    try {
      final response = await _api.post(
        AppEndpoints.rideEstimate,
        data: {
          'pickup': pickup.toJson(),
          'dropoff': dropoff.toJson(),
          'stops': [for (final stop in stops) stop.toJson()],
          'optionId': option.id,
          'pricePerKm': option.pricePerKm,
          'preferences': preferences.toJson(),
          ...bookingJson,
        },
        suppressErrorToast: true,
      );
      if (!_estimateEpoch.isCurrent(request)) return false;
      final estimate = FareEstimate.fromJson((response.data as Map)['data']);
      _estimate.value = estimate;
      if (estimate.meetGreetFee != null) _knownMeetGreetFee.value = estimate.meetGreetFee;
      return true;
    } catch (e) {
      log('loadEstimate failed: $e');
      if (_estimateEpoch.isCurrent(request)) _estimateProblem.value = RideLoadProblem.of(e);
      return false;
    } finally {
      if (_estimateEpoch.isCurrent(request)) _isEstimating.value = false;
    }
  }

  Future<void> refreshQuote() async {
    await loadEstimate();
  }
}
