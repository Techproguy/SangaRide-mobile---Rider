import 'dart:developer';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/api/airport_endpoints.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/model/models.dart';

class AirportController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<AirportCatalogState> _catalog = Rx<AirportCatalogState>(const AirportCatalogLoading());
  final Rx<AirportDraft> _draft = Rx<AirportDraft>(const AirportDraft());
  final Rx<FlightLookupState> _lookup = Rx<FlightLookupState>(const FlightIdle());
  int _lookupRequest = 0;

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
    _lookupRequest++;
    _draft.value = const AirportDraft();
    _lookup.value = const FlightIdle();
  }

  Future<void> loadCatalog() async {
    if (catalog is AirportCatalogReady) return;
    _catalog.value = const AirportCatalogLoading();
    try {
      final responses = await Future.wait([_api.get(AirportEndpoints.airports), _api.get(AirportEndpoints.airlines)]);
      final airports = _dataOf(responses[0].data);
      final airlines = _dataOf(responses[1].data);
      _catalog.value = AirportCatalogReady(
        AirportCatalog(
          airports: [
            for (final json in airports['airports'] as List) Airport.fromJson(Map<String, dynamic>.from(json as Map)),
          ],
          popularIds: List<String>.from(airports['popular'] as List),
          airlines: [
            for (final json in airlines['airlines'] as List) Airline.fromJson(Map<String, dynamic>.from(json as Map)),
          ],
        ),
      );
    } catch (e) {
      log('loadCatalog failed: $e');
      _catalog.value = const AirportCatalogFailed();
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
    _lookupRequest++;
    _lookup.value = const FlightIdle();
  }

  Future<bool> lookupFlight() async {
    final query = draft.query;
    if (query == null || lookup is FlightSearching) return false;
    final request = ++_lookupRequest;
    _lookup.value = const FlightSearching();
    try {
      final response = await _api.get(
        AirportEndpoints.flightLookup,
        queryParameters: query.toQuery(),
        suppressErrorToast: true,
      );
      if (request != _lookupRequest) return false;
      final data = _dataOf(response.data);
      _lookup.value = FlightFound(Flight.fromJson(Map<String, dynamic>.from(data['flight'] as Map)));
      return true;
    } on ApiException catch (e) {
      log('lookupFlight failed: $e');
      if (request == _lookupRequest) {
        _lookup.value = FlightLookupFailed(
          FlightProblem.fromCode(e.code),
          destination: e.data['destination'] as String?,
        );
      }
      return false;
    } catch (e) {
      log('lookupFlight failed: $e');
      if (request == _lookupRequest) _lookup.value = const FlightLookupFailed(FlightProblem.connection);
      return false;
    }
  }

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
