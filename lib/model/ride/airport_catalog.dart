import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class AirportRules {
  // TODO(#270): drop the passenger and luggage caps when the airport catalog sends airport.limits.maxPassengers and maxLuggage
  static const int maxPassengers = 6;
  static const int maxLuggage = 8;
  static const int maxFlightDigits = 4;
  static const int flightFieldLength = 8;
}

const _diacritics = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
};

List<String> _searchTokens(String text) {
  final folded = text.toLowerCase().split('').map((char) => _diacritics[char] ?? char).join();
  return folded.split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toList();
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
    final point = json.objectOrNull('coordinates') ?? json;
    return Airport(
      id: json.str('id'),
      iata: json.str('iata'),
      name: json.str('name'),
      city: json.str('city'),
      country: json.strOrNull('country'),
      coordinates: LatLng(point.number('lat').toDouble(), point.number('lng').toDouble()),
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
    final tokens = _searchTokens(query);
    if (tokens.isEmpty) return true;
    final haystack = _searchTokens('$name $city ${country ?? ''} $iata');
    return tokens.every(
      (token) => haystack.any((word) => word.startsWith(token)) || haystack.join(' ').contains(token),
    );
  }

  int rank(String query) {
    final tokens = _searchTokens(query);
    if (tokens.isEmpty) return 0;
    final joined = tokens.join(' ');
    if (iata.toLowerCase() == joined) return 0;
    if (_searchTokens(city).join(' ').startsWith(joined)) return 1;
    if (_searchTokens(name).join(' ').startsWith(joined)) return 2;
    return 3;
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

  List<Airport> search(String query) {
    final results = [
      for (final airport in airports)
        if (airport.matches(query)) airport,
    ];
    results.sort((a, b) => a.rank(query).compareTo(b.rank(query)));
    return results;
  }
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
