import 'dart:developer';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class RideRequestController extends GetxController {
  static const int maxStops = 3;

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
    _optionId.value = category == null ? null : _options.firstWhereOrNull((o) => o.category == category)?.id;
    _preferredCategory = category;
  }

  RideCategory? _preferredCategory;

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
    _tripType.value = type;
    _clearQuote();
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
    _scheduledAt.value = timing == RideTiming.now ? null : scheduledAt;
  }

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
          'tripType': tripType.name,
          'preferences': preferences.toJson(),
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
