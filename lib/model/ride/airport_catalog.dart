import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class AirportRules {
  static const int maxPassengers = 6;
  static const int maxLuggage = 8;
  static const int maxFlightDigits = 4;
  static const int flightFieldLength = 8;
}

class AirportTerminal {
  const AirportTerminal({required this.id, required this.name, required this.kind});

  factory AirportTerminal.fromJson(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    return AirportTerminal(id: json.str('id'), name: json.str('name'), kind: json.strOr('kind', ''));
  }

  final String id;
  final String name;
  final String kind;
}

class Airport {
  const Airport({
    required this.id,
    required this.iata,
    required this.name,
    required this.city,
    required this.coordinates,
    required this.terminals,
    required this.meetPoint,
    this.country,
    this.utcOffsetMinutes,
  });

  factory Airport.fromJson(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    return Airport(
      id: json.str('id'),
      iata: json.str('iata'),
      name: json.str('name'),
      city: json.str('city'),
      country: json.strOrNull('country'),
      coordinates: LatLng(json.number('lat').toDouble(), json.number('lng').toDouble()),
      terminals: json.listOf('terminals', (item) => AirportTerminal.fromJson(item.raw)),
      meetPoint: json.strOr('meetPoint', ''),
      utcOffsetMinutes: json.intOrNull('utcOffsetMinutes'),
    );
  }

  final String id;
  final String iata;
  final String name;
  final String city;
  final String? country;
  final LatLng coordinates;
  final List<AirportTerminal> terminals;
  final String meetPoint;
  final int? utcOffsetMinutes;

  DateTime localToday(DateTime serverNow) {
    final offset = utcOffsetMinutes;
    final local = offset == null ? serverNow.toLocal() : serverNow.toUtc().add(Duration(minutes: offset));
    return DateTime(local.year, local.month, local.day);
  }

  String get location => country == null ? city : '$city, $country';

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return '$name $city $iata'.toLowerCase().contains(needle);
  }

  Place toPlace({String? terminalName}) => Place(
    placeId: 'airport_$id',
    name: terminalName == null ? name : '$terminalName, $name',
    address: location,
    coordinates: coordinates,
  );
}

class Airline {
  const Airline({required this.code, required this.name});

  factory Airline.fromJson(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    return Airline(code: json.str('code'), name: json.str('name'));
  }

  final String code;
  final String name;
}

class AirportCatalog {
  const AirportCatalog({required this.airports, required this.popularIds, required this.airlines});

  final List<Airport> airports;
  final List<String> popularIds;
  final List<Airline> airlines;

  List<Airport> get popular => [for (final id in popularIds) ?airportById(id)];

  Airport? airportById(String id) => airports.where((airport) => airport.id == id).firstOrNull;

  List<Airport> search(String query) => [
    for (final airport in airports)
      if (airport.matches(query)) airport,
  ];
}

sealed class AirportCatalogState {
  const AirportCatalogState();
}

final class AirportCatalogLoading extends AirportCatalogState {
  const AirportCatalogLoading();
}

final class AirportCatalogFailed extends AirportCatalogState {
  const AirportCatalogFailed({this.problem = RideLoadProblem.connection});

  final RideLoadProblem problem;
}

final class AirportCatalogReady extends AirportCatalogState {
  const AirportCatalogReady(this.catalog);

  final AirportCatalog catalog;
}
