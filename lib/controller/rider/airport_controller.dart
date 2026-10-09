import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/api/airport_endpoints.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class AirportController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<AirportCatalogState> _catalog = Rx<AirportCatalogState>(const AirportCatalogLoading());
  final Rx<AirportDraft> _draft = Rx<AirportDraft>(const AirportDraft());
  final Rx<FlightLookupState> _lookup = Rx<FlightLookupState>(const FlightIdle());
  final _lookupEpoch = Epoch();
  DateTime? _catalogLoadedAt;
  StreamSubscription<void>? _resumeSubscription;

  @override
  void onInit() {
    super.onInit();
    _resumeSubscription = AppLifecycle.instance.onResume.listen((_) => _catalogLoadedAt = null);
  }

  @override
  void onClose() {
    _resumeSubscription?.cancel();
    super.onClose();
  }

  AirportCatalogState get catalog => _catalog.value;

  AirportCatalog? get readyCatalog => switch (catalog) {
    AirportCatalogReady(:final catalog) => catalog,
    AirportCatalogLoading() || AirportCatalogFailed() => null,
  };

  AirportDraft get draft => _draft.value;

  FlightLookupState get lookup => _lookup.value;

  Flight? get flight => switch (lookup) {
    FlightFound(:final flight) => flight,
    _ => null,
  };

  int get passengerLimit {
    final seats = Get.find<RideRequestController>().option?.maxSeats ?? AirportRules.maxPassengers;
    return math.min(seats, AirportRules.maxPassengers);
  }

  AirportBooking? get booking {
    final airport = draft.airport;
    final flight = this.flight;
    final pickupType = draft.pickupType;
    if (airport == null || flight == null || pickupType == null) return null;
    return AirportBooking(airport: airport, flight: flight, pickupType: pickupType, details: draft.details);
  }

  void begin() {
    _lookupEpoch.next();
    _draft.value = const AirportDraft();
    _lookup.value = const FlightIdle();
  }

  Future<void> loadCatalog({bool force = false}) async {
    final loadedAt = _catalogLoadedAt;
    final isFresh = loadedAt != null && DateTime.now().difference(loadedAt) < RideRequestController.catalogLifetime;
    if (catalog is AirportCatalogReady && isFresh && !force) return;
    if (catalog is! AirportCatalogReady) _catalog.value = const AirportCatalogLoading();
    try {
      final responses = await Future.wait([
        _api.get(AirportEndpoints.airports, suppressErrorToast: true),
        _api.get(AirportEndpoints.airlines, suppressErrorToast: true),
      ]);
      final airports = JsonReader.of((responses[0].data as Map)['data']);
      final airlines = JsonReader.of((responses[1].data as Map)['data']);
      _catalog.value = AirportCatalogReady(
        AirportCatalog(
          airports: airports.listOf('airports', (item) => Airport.fromJson(item.raw)),
          popularIds: airports.strings('popular'),
          airlines: airlines.listOf('airlines', (item) => Airline.fromJson(item.raw)),
        ),
      );
      _catalogLoadedAt = DateTime.now();
    } catch (e) {
      log('loadCatalog failed: $e');
      if (catalog is! AirportCatalogReady) _catalog.value = AirportCatalogFailed(problem: RideLoadProblem.of(e));
    }
  }

  void selectAirport(Airport airport) {
    if (draft.airport?.id == airport.id) return;
    _draft.value = draft.copyWith(airport: airport);
    _resetLookup();
  }

  void selectAirline(Airline airline) {
    if (draft.airline?.code == airline.code) return;
    _draft.value = draft.copyWith(airline: airline);
    _resetLookup();
  }

  void setNumberText(String text) {
    if (text == draft.numberText) return;
    _draft.value = draft.copyWith(numberText: text);
    _resetLookup();
  }

  void setArrivalDate(DateTime date) {
    _draft.value = draft.copyWith(arrivalDate: DateTime(date.year, date.month, date.day));
    _resetLookup();
  }

  void setLuggageCount(int count) =>
      _draft.value = draft.copyWith(details: draft.details.copyWith(luggageCount: count));

  void setLuggageSize(LuggageSize size) =>
      _draft.value = draft.copyWith(details: draft.details.copyWith(luggageSize: size));

  void setPassengers(int passengers) =>
      _draft.value = draft.copyWith(details: draft.details.copyWith(passengers: passengers.clamp(1, passengerLimit)));

  void setAssistance(Assistance assistance) =>
      _draft.value = draft.copyWith(details: draft.details.copyWith(assistance: assistance));

  void setPickupType(PickupType type) => _draft.value = draft.copyWith(pickupType: type);

  void commitPickup() {
    final airport = draft.airport;
    if (airport == null) return;
    Get.find<RideRequestController>().setPickup(airport.toPlace(terminalName: flight?.terminal?.name));
  }

  void _resetLookup() {
    _lookupEpoch.next();
    _lookup.value = const FlightIdle();
  }

  Future<bool> lookupFlight() async {
    final query = draft.query;
    if (query == null || lookup is FlightSearching) return false;
    final request = _lookupEpoch.next();
    _lookup.value = const FlightSearching();
    try {
      final response = await _api.get(
        AirportEndpoints.flightLookup,
        queryParameters: query.toQuery(),
        suppressErrorToast: true,
      );
      if (!_lookupEpoch.isCurrent(request)) return false;
      final data = response.dataMap;
      _lookup.value = FlightFound(Flight.fromJson(Map<String, dynamic>.from(data['flight'] as Map)));
      return true;
    } catch (e) {
      log('lookupFlight failed: $e');
      if (_lookupEpoch.isCurrent(request)) {
        _lookup.value = FlightLookupFailed(
          FlightProblem.of(e),
          destination: e is ApiException ? e.data['destination'] as String? : null,
        );
      }
      return false;
    }
  }
}
