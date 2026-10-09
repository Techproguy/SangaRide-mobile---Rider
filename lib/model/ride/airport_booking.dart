import 'package:sanga_ride/model/ride/airport_catalog.dart';
import 'package:sanga_ride/model/ride/flight.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum LuggageSize {
  small('small', 'Small'),
  medium('medium', 'Medium'),
  large('large', 'Large');

  const LuggageSize(this.code, this.label);

  final String code;
  final String label;
}

enum Assistance {
  none('none', 'None'),
  wheelchair('wheelchair', 'Wheelchair'),
  extraHelp('extra_help', 'Extra help');

  const Assistance(this.code, this.label);

  final String code;
  final String label;

  static Assistance fromCode(String? code) => codedEnum(values, (assistance) => assistance.code, code, orElse: none);
}

enum PickupType {
  arrivalZone('arrival_zone', 'Arrival pick up zone', 'Meet your driver at the official arrivals pick up area'),
  meetGreet('meet_greet', 'Meet and greet', 'Your driver waits in the arrival hall with a name sign');

  const PickupType(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  static PickupType fromCode(String? code) => codedEnum(values, (type) => type.code, code, orElse: arrivalZone);
}

class ArrivalDetails {
  const ArrivalDetails({
    this.luggageCount = 1,
    this.luggageSize = LuggageSize.medium,
    this.passengers = 1,
    this.assistance = Assistance.none,
  });

  final int luggageCount;
  final LuggageSize luggageSize;
  final int passengers;
  final Assistance assistance;

  String get luggageLabel {
    if (luggageCount == 0) return 'No luggage';
    final bags = luggageCount == 1 ? 'bag' : 'bags';
    return '$luggageCount ${luggageSize.label.toLowerCase()} $bags';
  }

  String get passengersLabel => passengers == 1 ? '1 passenger' : '$passengers passengers';

  ArrivalDetails copyWith({int? luggageCount, LuggageSize? luggageSize, int? passengers, Assistance? assistance}) =>
      ArrivalDetails(
        luggageCount: luggageCount ?? this.luggageCount,
        luggageSize: luggageSize ?? this.luggageSize,
        passengers: passengers ?? this.passengers,
        assistance: assistance ?? this.assistance,
      );
}

class AirportBooking {
  const AirportBooking({required this.airport, required this.flight, required this.pickupType, required this.details});

  final Airport airport;
  final Flight flight;
  final PickupType pickupType;
  final ArrivalDetails details;

  int get passengers => details.passengers;

  Map<String, dynamic> toJson() => {
    'airportId': airport.id,
    'flightId': flight.id,
    if (flight.terminal case final terminal?) 'terminalId': terminal.id,
    'pickupType': pickupType.code,
    'luggage': {'count': details.luggageCount, 'size': details.luggageSize.code},
    'passengers': details.passengers,
    'assistance': details.assistance.code,
  };
}

class ScheduledAirport {
  const ScheduledAirport({
    required this.flightNumber,
    required this.airline,
    required this.estimatedArrival,
    required this.passengers,
    required this.luggage,
    required this.assistance,
    required this.pickupType,
    required this.meetPoint,
    required this.status,
    required this.airlineCode,
    this.terminal,
    this.origin,
    this.destination,
  });

  factory ScheduledAirport.fromJson(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    final flightNumber = json.str('flightNumber');
    return ScheduledAirport(
      flightNumber: flightNumber,
      airline: json.strOr('airline', ''),
      airlineCode: json.strOr('airlineCode', flightNumber.split(' ').first),
      estimatedArrival: json.time('estimatedArrival').toLocal(),
      terminal: json.strOrNull('terminal'),
      passengers: json.intOr('passengers', 1),
      luggage: json.strOr('luggage', ''),
      assistance: Assistance.fromCode(json.strOrNull('assistance')),
      pickupType: PickupType.fromCode(json.strOrNull('pickupType')),
      meetPoint: json.strOr('meetPoint', ''),
      status: FlightStatus.fromCode(json.strOrNull('flightStatus')),
      origin: _city(json.objectOrNull('origin')),
      destination: _city(json.objectOrNull('destination')),
    );
  }

  static FlightCity? _city(JsonReader? json) {
    if (json == null) return null;
    final city = json.strOrNull('city');
    return city == null ? null : FlightCity(city: city, iata: json.strOr('iata', ''));
  }

  final String flightNumber;
  final String airline;
  final String airlineCode;
  final FlightCity? origin;
  final FlightCity? destination;
  final DateTime estimatedArrival;
  final String? terminal;
  final int passengers;
  final String luggage;
  final Assistance assistance;
  final PickupType pickupType;
  final String meetPoint;
  final FlightStatus status;

  String get passengersLabel => passengers == 1 ? '1 passenger' : '$passengers passengers';
}

class TripAirport {
  const TripAirport({required this.flightNumber, required this.status, required this.meetPoint});

  factory TripAirport.fromJson(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    return TripAirport(
      flightNumber: json.str('flightNumber'),
      status: FlightStatus.fromCode(json.strOrNull('flightStatus')),
      meetPoint: json.str('meetPoint'),
    );
  }

  final String flightNumber;
  final FlightStatus status;
  final String meetPoint;
}

class AirportDraft {
  const AirportDraft({
    this.airport,
    this.airline,
    this.numberText = '',
    this.arrivalDate,
    this.details = const ArrivalDetails(),
    this.pickupType,
  });

  final Airport? airport;
  final Airline? airline;
  final String numberText;
  final DateTime? arrivalDate;
  final ArrivalDetails details;
  final PickupType? pickupType;

  String? get flightDigits {
    final airline = this.airline;
    return airline == null ? null : FlightNumber.digitsOf(numberText, airlineCode: airline.code);
  }

  bool get hasNumberIssue => numberText.trim().isNotEmpty && flightDigits == null;

  FlightQuery? get query {
    final airport = this.airport;
    final airline = this.airline;
    final date = arrivalDate;
    final digits = flightDigits;
    if (airport == null || airline == null || date == null || digits == null) return null;
    return FlightQuery(airlineCode: airline.code, number: digits, date: date, airportId: airport.id);
  }

  AirportDraft copyWith({
    Airport? airport,
    Airline? airline,
    String? numberText,
    DateTime? arrivalDate,
    ArrivalDetails? details,
    PickupType? pickupType,
  }) => AirportDraft(
    airport: airport ?? this.airport,
    airline: airline ?? this.airline,
    numberText: numberText ?? this.numberText,
    arrivalDate: arrivalDate ?? this.arrivalDate,
    details: details ?? this.details,
    pickupType: pickupType ?? this.pickupType,
  );
}
