import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/ride/airport_catalog.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum FlightStatus {
  scheduled('scheduled'),
  delayed('delayed'),
  landed('landed'),
  cancelled('cancelled'),
  diverted('diverted');

  const FlightStatus(this.code);

  final String code;

  bool get cannotBeBooked => this == cancelled || this == diverted;

  static FlightStatus fromCode(String? code) => codedEnum(values, (status) => status.code, code, orElse: scheduled);
}

class FlightCity {
  const FlightCity({required this.city, required this.iata});

  factory FlightCity.fromJson(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    return FlightCity(city: json.str('city'), iata: json.str('iata'));
  }

  final String city;
  final String iata;
}

class FlightTerminal {
  const FlightTerminal({required this.id, required this.name});

  factory FlightTerminal.fromJson(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    return FlightTerminal(id: json.str('id'), name: json.str('name'));
  }

  final String id;
  final String name;
}

class Flight {
  const Flight({
    required this.id,
    required this.airline,
    required this.number,
    required this.origin,
    required this.destination,
    required this.scheduledArrival,
    required this.estimatedArrival,
    required this.status,
    this.terminal,
  });

  factory Flight.fromJson(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    final terminal = json.objectOrNull('terminal');
    return Flight(
      id: json.str('id'),
      airline: Airline.fromJson(json.object('airline').raw),
      number: json.str('number'),
      origin: FlightCity.fromJson(json.object('origin').raw),
      destination: FlightCity.fromJson(json.object('destination').raw),
      scheduledArrival: json.time('scheduledArrival').toLocal(),
      estimatedArrival: json.time('estimatedArrival').toLocal(),
      terminal: terminal == null ? null : FlightTerminal.fromJson(terminal.raw),
      status: FlightStatus.fromCode(json.strOrNull('status')),
    );
  }

  final String id;
  final Airline airline;
  final String number;
  final FlightCity origin;
  final FlightCity destination;
  final DateTime scheduledArrival;
  final DateTime estimatedArrival;
  final FlightTerminal? terminal;
  final FlightStatus status;

  Duration get delay {
    final difference = estimatedArrival.difference(scheduledArrival);
    return difference.isNegative ? Duration.zero : difference;
  }
}

class FlightQuery {
  const FlightQuery({required this.airlineCode, required this.number, required this.date, required this.airportId});

  final String airlineCode;
  final String number;
  final DateTime date;
  final String airportId;

  static String dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toQuery() => {
    'airline': airlineCode,
    'number': number,
    'date': dateParam(date),
    'airportId': airportId,
  };
}

abstract final class FlightNumber {
  static final RegExp _allowed = RegExp(r'[^A-Za-z0-9 ]');

  static String clean(String raw) => raw.replaceAll(_allowed, '').toUpperCase();

  static String? digitsOf(String raw, {required String airlineCode}) {
    var text = clean(raw).replaceAll(' ', '');
    if (text.startsWith(airlineCode.toUpperCase())) text = text.substring(airlineCode.length);
    if (text.isEmpty || text.length > AirportRules.maxFlightDigits) return null;
    if (!RegExp(r'^\d+$').hasMatch(text)) return null;
    final trimmed = text.replaceFirst(RegExp(r'^0+'), '');
    return trimmed.isEmpty ? null : trimmed;
  }

  static String display(String airlineCode, String digits) => '$airlineCode $digits';
}

enum FlightProblem {
  notFound('flight_not_found', 'We can’t find that flight. Check the airline, number and date.'),
  wrongAirport('wrong_airport', 'That flight lands at a different airport. Check your flight or pick another airport.'),
  dateOutOfRange('date_out_of_range', 'We can only plan pick ups from today up to 30 days ahead.'),
  alreadyArrived('flight_already_arrived', 'That flight landed a while ago. Check the date and number.'),
  connection('connection', CommonCopy.offline),
  unknown('unknown', 'We couldn’t check that flight. Try again in a moment.');

  const FlightProblem(this.code, this.message);

  final String code;
  final String message;

  static FlightProblem fromCode(String? code) => enumByCode(values, code, (problem) => problem.code, unknown);

  static FlightProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => fromCode(code),
    _ => unknown,
  };
}

sealed class FlightLookupState {
  const FlightLookupState();
}

final class FlightIdle extends FlightLookupState {
  const FlightIdle();
}

final class FlightSearching extends FlightLookupState {
  const FlightSearching();
}

final class FlightFound extends FlightLookupState {
  const FlightFound(this.flight);

  final Flight flight;
}

final class FlightLookupFailed extends FlightLookupState {
  const FlightLookupFailed(this.problem, {this.destination});

  final FlightProblem problem;
  final String? destination;

  String get message {
    final destination = this.destination;
    if (problem == FlightProblem.wrongAirport && destination != null) {
      return 'That flight lands in $destination. Go back and pick that airport, or check your flight number.';
    }
    return problem.message;
  }
}
