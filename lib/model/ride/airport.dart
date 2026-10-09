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

  Airline? airlineByCode(String code) => airlines.where((airline) => airline.code == code).firstOrNull;

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

enum FlightStatus {
  scheduled('scheduled'),
  delayed('delayed'),
  landed('landed'),
  cancelled('cancelled'),
  diverted('diverted');

  const FlightStatus(this.code);

  final String code;

  bool get cannotBeBooked => this == cancelled || this == diverted;

  static FlightStatus fromCode(String? code) =>
      values.firstWhere((status) => status.code == code, orElse: () => scheduled);
}

class FlightCity {
  const FlightCity({required this.city, required this.iata});

  factory FlightCity.fromJson(Map<String, dynamic> json) =>
      FlightCity(city: json['city'] as String, iata: json['iata'] as String);

  final String city;
  final String iata;
}

class FlightTerminal {
  const FlightTerminal({required this.id, required this.name});

  factory FlightTerminal.fromJson(Map<String, dynamic> json) =>
      FlightTerminal(id: json['id'] as String, name: json['name'] as String);

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

  factory Flight.fromJson(Map<String, dynamic> json) {
    final terminal = json['terminal'] as Map?;
    return Flight(
      id: json['id'] as String,
      airline: Airline.fromJson(Map<String, dynamic>.from(json['airline'] as Map)),
      number: json['number'] as String,
      origin: FlightCity.fromJson(Map<String, dynamic>.from(json['origin'] as Map)),
      destination: FlightCity.fromJson(Map<String, dynamic>.from(json['destination'] as Map)),
      scheduledArrival: DateTime.parse(json['scheduledArrival'] as String).toLocal(),
      estimatedArrival: DateTime.parse(json['estimatedArrival'] as String).toLocal(),
      terminal: terminal == null ? null : FlightTerminal.fromJson(Map<String, dynamic>.from(terminal)),
      status: FlightStatus.fromCode(json['status'] as String?),
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
  connection('connection', 'You’re offline. Check your connection and give it another go.'),
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

  static Assistance fromCode(String? code) =>
      values.firstWhere((assistance) => assistance.code == code, orElse: () => none);
}

enum PickupType {
  arrivalZone('arrival_zone', 'Arrival pick up zone', 'Meet your driver at the official arrivals pick up area'),
  meetGreet('meet_greet', 'Meet and greet', 'Your driver waits in the arrival hall with a name sign');

  const PickupType(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  static PickupType fromCode(String? code) => values.firstWhere((type) => type.code == code, orElse: () => arrivalZone);
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
    this.terminal,
  });

  factory ScheduledAirport.fromJson(Map<String, dynamic> json) => ScheduledAirport(
    flightNumber: json['flightNumber'] as String,
    airline: json['airline'] as String,
    estimatedArrival: DateTime.parse(json['estimatedArrival'] as String).toLocal(),
    terminal: json['terminal'] as String?,
    passengers: (json['passengers'] as num).toInt(),
    luggage: json['luggage'] as String,
    assistance: Assistance.fromCode(json['assistance'] as String?),
    pickupType: PickupType.fromCode(json['pickupType'] as String?),
    meetPoint: json['meetPoint'] as String,
    status: FlightStatus.fromCode(json['flightStatus'] as String?),
  );

  final String flightNumber;
  final String airline;
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

  factory TripAirport.fromJson(Map<String, dynamic> json) => TripAirport(
    flightNumber: json['flightNumber'] as String,
    status: FlightStatus.fromCode(json['flightStatus'] as String?),
    meetPoint: json['meetPoint'] as String,
  );

  final String flightNumber;
  final FlightStatus status;
  final String meetPoint;
}

enum FlightEventType {
  scheduledArrival('scheduled_arrival'),
  landed('landed'),
  baggageClaimed('baggage_claimed'),
  atMeetPoint('at_meet_point'),
  met('met');

  const FlightEventType(this.code);

  final String code;

  static FlightEventType? fromCode(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

enum FlightEventState {
  done('done'),
  current('current'),
  pending('pending');

  const FlightEventState(this.code);

  final String code;

  static FlightEventState fromCode(String? code) =>
      values.firstWhere((state) => state.code == code, orElse: () => pending);
}

class FlightEvent {
  const FlightEvent({required this.type, required this.state, this.at});

  static FlightEvent? tryParse(Map<String, dynamic> json) {
    final type = FlightEventType.fromCode(json['type'] as String?);
    if (type == null) return null;
    final at = json['at'] as String?;
    return FlightEvent(
      type: type,
      state: FlightEventState.fromCode(json['state'] as String?),
      at: at == null ? null : DateTime.parse(at).toLocal(),
    );
  }

  final FlightEventType type;
  final FlightEventState state;
  final DateTime? at;
}

class FlightCancellation {
  const FlightCancellation({required this.freeUntil});

  factory FlightCancellation.fromJson(Map<String, dynamic> json) =>
      FlightCancellation(freeUntil: DateTime.parse(json['freeUntil'] as String).toLocal());

  final DateTime freeUntil;
}

class FlightTracking {
  const FlightTracking({
    required this.flight,
    required this.events,
    required this.pickupAt,
    required this.pickupAdjusted,
    this.cancellation,
  });

  factory FlightTracking.fromJson(Map<String, dynamic> json) {
    final cancellation = json['cancellation'] as Map?;
    return FlightTracking(
      flight: Flight.fromJson(Map<String, dynamic>.from(json['flight'] as Map)),
      events: [
        for (final event in json['events'] as List? ?? const [])
          ?FlightEvent.tryParse(Map<String, dynamic>.from(event as Map)),
      ],
      pickupAt: DateTime.parse(json['pickupAt'] as String).toLocal(),
      pickupAdjusted: json['pickupAdjusted'] as bool? ?? false,
      cancellation: cancellation == null ? null : FlightCancellation.fromJson(Map<String, dynamic>.from(cancellation)),
    );
  }

  final Flight flight;
  final List<FlightEvent> events;
  final DateTime pickupAt;
  final bool pickupAdjusted;
  final FlightCancellation? cancellation;

  FlightEvent? eventOf(FlightEventType type) => events.where((event) => event.type == type).firstOrNull;

  bool get hasLanded => eventOf(FlightEventType.landed)?.state == FlightEventState.done;

  bool get isDisrupted => flight.status.cannotBeBooked;
}

enum FlightTrackingFailure {
  notFound('We can’t find this flight', 'It may no longer be on your ride. Head back and try again.', canRetry: false),
  connection('We couldn’t load your flight', 'Check your connection and give it another go.', canRetry: true);

  const FlightTrackingFailure(this.title, this.message, {required this.canRetry});

  final String title;
  final String message;
  final bool canRetry;
}

sealed class FlightTrackingState {
  const FlightTrackingState();
}

final class FlightTrackingLoading extends FlightTrackingState {
  const FlightTrackingLoading();
}

final class FlightTrackingFailed extends FlightTrackingState {
  const FlightTrackingFailed(this.reason);

  final FlightTrackingFailure reason;
}

final class FlightTrackingReady extends FlightTrackingState {
  const FlightTrackingReady(this.tracking, {this.isRefreshing = false});

  final FlightTracking tracking;
  final bool isRefreshing;
}

sealed class DriverNotifyState {
  const DriverNotifyState();
}

final class NotifyIdle extends DriverNotifyState {
  const NotifyIdle();
}

final class NotifySending extends DriverNotifyState {
  const NotifySending();
}

final class NotifySent extends DriverNotifyState {
  const NotifySent(this.at);

  final DateTime at;
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
