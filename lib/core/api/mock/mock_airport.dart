import 'package:sanga_ride/core/api/airport_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';

class MockAirportDecision {
  const MockAirportDecision({required this.pickupAt, required this.isLive});

  final DateTime pickupAt;
  final bool isLive;
}

class MockAirportSeed {
  const MockAirportSeed({
    required this.id,
    required this.pickupAt,
    required this.category,
    required this.pickup,
    required this.dropoff,
    required this.fare,
  });

  final String id;
  final DateTime pickupAt;
  final String category;
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final num fare;
}

abstract final class MockAirport {
  static final List<MockRoute> routes = _build();

  static List<MockAirportSeed> get seeds => _seeds;

  static const num meetGreetFeeNaira = 3500;

  static const Duration _arrivalZoneLead = Duration(minutes: 30);
  static const Duration _meetGreetLead = Duration(minutes: 45);
  static const Duration _liveWindow = Duration(minutes: 60);
  static const Duration _landedGrace = Duration(hours: 2);
  static const Duration _baggageAfter = Duration(minutes: 2);
  static const Duration _meetPointAfter = Duration(minutes: 4);
  static const Duration _delay = Duration(minutes: 40);
  static const int _windowDays = 30;
  static const List<String> _happyFlights = ['BA75', 'P47120'];

  static const List<Map<String, dynamic>> _airports = [
    {
      'id': 'los',
      'iata': 'LOS',
      'utcOffsetMinutes': 60,
      'name': 'Murtala Muhammed International Airport',
      'city': 'Lagos',
      'country': 'Nigeria',
      'lat': 6.5774,
      'lng': 3.3212,
      'terminals': [
        {'id': 'los_t1', 'name': 'Terminal 1', 'kind': 'international'},
        {'id': 'los_t2', 'name': 'Terminal 2', 'kind': 'domestic'},
      ],
      'meetPoint': 'Arrival hall, by the Sanga sign',
    },
    {
      'id': 'abv',
      'iata': 'ABV',
      'utcOffsetMinutes': 60,
      'name': 'Nnamdi Azikiwe International Airport',
      'city': 'Abuja',
      'country': 'Nigeria',
      'lat': 9.0068,
      'lng': 7.2632,
      'terminals': [
        {'id': 'abv_t1', 'name': 'International Terminal', 'kind': 'international'},
        {'id': 'abv_t2', 'name': 'Domestic Terminal', 'kind': 'domestic'},
      ],
      'meetPoint': 'Arrivals lobby, by the Sanga sign',
    },
    {
      'id': 'phc',
      'iata': 'PHC',
      'utcOffsetMinutes': 60,
      'name': 'Port Harcourt International Airport',
      'city': 'Port Harcourt',
      'country': 'Nigeria',
      'lat': 5.0155,
      'lng': 6.9496,
      'terminals': [
        {'id': 'phc_t1', 'name': 'International Terminal', 'kind': 'international'},
        {'id': 'phc_t2', 'name': 'Domestic Terminal', 'kind': 'domestic'},
      ],
      'meetPoint': 'Arrival hall, near the car park',
    },
    {
      'id': 'kan',
      'iata': 'KAN',
      'utcOffsetMinutes': 60,
      'name': 'Mallam Aminu Kano International Airport',
      'city': 'Kano',
      'country': 'Nigeria',
      'lat': 12.0476,
      'lng': 8.5246,
      'terminals': [
        {'id': 'kan_t1', 'name': 'Main Terminal', 'kind': 'international'},
      ],
      'meetPoint': 'Arrival hall, by the main doors',
    },
    {
      'id': 'enu',
      'iata': 'ENU',
      'utcOffsetMinutes': 60,
      'name': 'Akanu Ibiam International Airport',
      'city': 'Enugu',
      'country': 'Nigeria',
      'lat': 6.4743,
      'lng': 7.5618,
      'terminals': [
        {'id': 'enu_t1', 'name': 'Main Terminal', 'kind': 'international'},
      ],
      'meetPoint': 'Arrival hall, by the information desk',
    },
  ];

  static const List<String> _popular = ['los', 'abv', 'phc'];

  static const List<Map<String, dynamic>> _airlines = [
    {'code': 'BA', 'name': 'British Airways'},
    {'code': 'P4', 'name': 'Air Peace'},
    {'code': 'VS', 'name': 'Virgin Atlantic'},
    {'code': 'LH', 'name': 'Lufthansa'},
    {'code': 'TK', 'name': 'Turkish Airlines'},
    {'code': 'ET', 'name': 'Ethiopian Airlines'},
    {'code': 'EK', 'name': 'Emirates'},
    {'code': 'QR', 'name': 'Qatar Airways'},
    {'code': 'QI', 'name': 'Ibom Air'},
    {'code': 'VK', 'name': 'ValueJet'},
    {'code': 'OJ', 'name': 'Overland Airways'},
  ];

  static const Set<String> _domesticCarriers = {'P4', 'QI', 'VK', 'OJ'};

  static const List<Map<String, dynamic>> _internationalOrigins = [
    {'city': 'London', 'iata': 'LHR'},
    {'city': 'Dubai', 'iata': 'DXB'},
    {'city': 'Istanbul', 'iata': 'IST'},
    {'city': 'Addis Ababa', 'iata': 'ADD'},
    {'city': 'Doha', 'iata': 'DOH'},
    {'city': 'Frankfurt', 'iata': 'FRA'},
  ];

  static const Map<String, Map<String, dynamic>> _hubs = {
    'BA': {'city': 'London', 'iata': 'LHR'},
    'VS': {'city': 'London', 'iata': 'LHR'},
    'EK': {'city': 'Dubai', 'iata': 'DXB'},
    'TK': {'city': 'Istanbul', 'iata': 'IST'},
    'ET': {'city': 'Addis Ababa', 'iata': 'ADD'},
    'QR': {'city': 'Doha', 'iata': 'DOH'},
    'LH': {'city': 'Frankfurt', 'iata': 'FRA'},
  };

  static final Map<String, _Flight> _flights = {};
  static final Map<String, _AirportRide> _rides = {};
  static final List<MockAirportSeed> _seeds = [];

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static List<MockRoute> _build() {
    _seed(DateTime.now());
    return [
      MockRoute.get(
        AirportEndpoints.airports,
        (_) => {'airports': _airports, 'popular': _popular, 'serverTime': _iso(DateTime.now())},
      ),
      MockRoute.get(AirportEndpoints.airlines, (_) => {'airlines': _airlines, 'serverTime': _iso(DateTime.now())}),
      MockRoute.get(AirportEndpoints.flightLookup, _lookup),
      MockRoute.get(AirportEndpoints.rideFlight, _tracking),
      MockRoute.post(AirportEndpoints.notifyDriver, _notify),
    ];
  }

  static Map<String, dynamic> _airportOf(String id) {
    final airport = _airports.where((airport) => airport['id'] == id).firstOrNull;
    if (airport == null) throw const MockFailure(404, 'We can’t find that airport.', code: 'not_found');
    return airport;
  }

  static Map<String, dynamic> _airlineOf(String code) {
    final airline = _airlines.where((airline) => airline['code'] == code).firstOrNull;
    if (airline == null) throw const MockFailure(404, 'We can’t find that flight.', code: 'flight_not_found');
    return airline;
  }

  static DateTime _today(DateTime now) => DateTime(now.year, now.month, now.day);

  static DateTime _minute(DateTime time) => DateTime(time.year, time.month, time.day, time.hour, time.minute);

  static DateTime _scheduledFor(String code, int number, DateTime date, DateTime now) {
    final key = '$code$number';
    if (date == _today(now)) {
      final base = switch (key) {
        'P47120' => now.add(const Duration(minutes: 40)),
        'BA75' => now.add(const Duration(hours: 3)),
        _ when number % 10 == 6 => now.subtract(const Duration(hours: 3)),
        _ when number % 10 == 5 => now.subtract(const Duration(minutes: 30)),
        _ => now.add(Duration(hours: 2 + number % 7)),
      };
      return _minute(base);
    }
    return switch (key) {
      'BA75' => DateTime(date.year, date.month, date.day, 19, 15),
      'P47120' => DateTime(date.year, date.month, date.day, 9, 40),
      _ => DateTime(date.year, date.month, date.day, 6 + number % 16, (number % 12) * 5),
    };
  }

  static String _statusBase(int number) => switch (number % 10) {
    8 => 'cancelled',
    7 => 'diverted',
    _ => 'scheduled',
  };

  static Map<String, dynamic> _originFor(String code, int number, String destinationId) {
    if (_domesticCarriers.contains(code)) {
      final others = [
        for (final airport in _airports)
          if (airport['id'] != destinationId) airport,
      ];
      final origin = others[number % others.length];
      return {'city': origin['city'], 'iata': origin['iata']};
    }
    return _hubs[code] ?? _internationalOrigins[number % _internationalOrigins.length];
  }

  static Map<String, dynamic> _terminalFor(Map<String, dynamic> airport, String code) {
    final terminals = (airport['terminals'] as List).cast<Map<String, dynamic>>();
    final kind = _domesticCarriers.contains(code) ? 'domestic' : 'international';
    return terminals.where((terminal) => terminal['kind'] == kind).firstOrNull ?? terminals.first;
  }

  static _Flight _create({
    required String code,
    required int number,
    required DateTime scheduled,
    required Map<String, dynamic> destination,
    required Duration delay,
    required String baseStatus,
  }) {
    final airline = _airlineOf(code);
    final terminal = _terminalFor(destination, code);
    final date =
        '${scheduled.year}${scheduled.month.toString().padLeft(2, '0')}${scheduled.day.toString().padLeft(2, '0')}';
    final flight = _Flight(
      id: 'fl_${code.toLowerCase()}${number}_$date',
      airline: airline,
      number: number,
      origin: _originFor(code, number, destination['id'] as String),
      destination: {'city': destination['city'], 'iata': destination['iata']},
      destinationId: destination['id'] as String,
      scheduled: scheduled,
      delay: delay,
      terminal: {'id': terminal['id'], 'name': terminal['name']},
      baseStatus: baseStatus,
    );
    _flights[flight.id] = flight;
    return flight;
  }

  static Object? _lookup(MockRequest request) {
    final now = DateTime.now();
    final code = (request.query['airline'] as String? ?? '').toUpperCase();
    final number = int.tryParse('${request.query['number']}');
    final date = DateTime.tryParse('${request.query['date']}');
    final airport = _airportOf('${request.query['airportId']}');
    _airlineOf(code);
    if (number == null || number <= 0 || date == null) {
      throw const MockFailure(404, 'We can’t find that flight.', code: 'flight_not_found');
    }
    final day = DateTime(date.year, date.month, date.day);
    final today = _today(now);
    if (day.isBefore(today) || day.isAfter(DateTime(today.year, today.month, today.day + _windowDays))) {
      throw const MockFailure(
        422,
        'We can only look up flights from today to 30 days ahead.',
        code: 'date_out_of_range',
      );
    }
    if (number % 10 == 0 && !_happyFlights.contains('$code$number')) {
      throw const MockFailure(404, 'We can’t find that flight.', code: 'flight_not_found');
    }
    if (number.toString().startsWith('5') && !_happyFlights.contains('$code$number')) {
      final other = _airports.firstWhere((candidate) => candidate['id'] != airport['id']);
      throw MockFailure(
        422,
        'That flight lands somewhere else.',
        code: 'wrong_airport',
        data: {'destination': other['city']},
      );
    }
    final scheduled = _scheduledFor(code, number, day, now);
    final delay = number % 10 == 9 ? _delay : Duration.zero;
    final flight = _create(
      code: code,
      number: number,
      scheduled: scheduled,
      destination: airport,
      delay: delay,
      baseStatus: _statusBase(number),
    );
    if (flight.estimated.isBefore(now.subtract(_landedGrace))) {
      throw const MockFailure(422, 'That flight landed a while ago.', code: 'flight_already_arrived');
    }
    return {'flight': flight.json(now), 'serverTime': _iso(now)};
  }

  static MockAirportDecision decide(Map<String, dynamic> body) {
    final block = Map<String, dynamic>.from(body['airport'] as Map);
    final flight = _flights[block['flightId']];
    if (flight == null) throw const MockFailure(404, 'We can’t find that flight.', code: 'flight_not_found');
    if (flight.isDisrupted) {
      throw const MockFailure(422, 'That flight can’t be booked.', code: 'flight_unavailable');
    }
    final lead = block['pickupType'] == 'meet_greet' ? _meetGreetLead : _arrivalZoneLead;
    return MockAirportDecision(
      pickupAt: flight.estimated.add(lead),
      isLive: flight.estimated.isBefore(DateTime.now().add(_liveWindow)),
    );
  }

  static void register(String rideId, Map<String, dynamic> body, DateTime pickupAt) {
    final block = Map<String, dynamic>.from(body['airport'] as Map);
    final flight = _flights[block['flightId']];
    if (flight == null) return;
    final luggage = Map<String, dynamic>.from(block['luggage'] as Map);
    _rides[rideId] = _AirportRide(
      flight: flight,
      pickupAt: pickupAt,
      pickupType: block['pickupType'] as String,
      passengers: (block['passengers'] as num).toInt(),
      luggageCount: (luggage['count'] as num).toInt(),
      luggageSize: luggage['size'] as String,
      assistance: block['assistance'] as String,
    );
  }

  static void attachLive(String tripId, Map<String, dynamic>? body) {
    if (body == null || body['airport'] == null) return;
    register(tripId, body, decide(body).pickupAt);
  }

  static num meetGreetFee(Map<String, dynamic> body) {
    final block = body['airport'];
    return block is Map && block['pickupType'] == 'meet_greet' ? meetGreetFeeNaira : 0;
  }

  static bool hasRide(String id) => _rides.containsKey(id);

  static Map<String, dynamic>? display(String id) {
    final ride = _rides[id];
    if (ride == null) return null;
    final now = DateTime.now();
    final airport = _airportOf(ride.flight.destinationId);
    return {
      'flightNumber': ride.flight.label,
      'airline': ride.flight.airline['name'],
      'airlineCode': ride.flight.airline['code'],
      'origin': ride.flight.origin,
      'destination': ride.flight.destination,
      'estimatedArrival': _iso(ride.flight.estimated),
      'terminal': ride.flight.terminal['name'],
      'passengers': ride.passengers,
      'luggage': ride.luggageLabel,
      'assistance': ride.assistance,
      'pickupType': ride.pickupType,
      'meetPoint': airport['meetPoint'],
      'flightStatus': ride.flight.statusAt(now),
    };
  }

  static Map<String, dynamic>? tripBlock(String id) {
    final ride = _rides[id];
    if (ride == null) return null;
    final airport = _airportOf(ride.flight.destinationId);
    return {
      'flightNumber': ride.flight.label,
      'flightStatus': ride.flight.statusAt(DateTime.now()),
      'meetPoint': airport['meetPoint'],
    };
  }

  static _AirportRide _requireRide(MockRequest request) {
    final ride = _rides[request.params['id']];
    if (ride == null) throw const MockFailure(404, 'We can’t find that flight.', code: 'not_found');
    return ride;
  }

  static Object? _tracking(MockRequest request) {
    final ride = _requireRide(request);
    final now = DateTime.now();
    final flight = ride.flight;
    return {
      'flight': flight.json(now),
      'events': _events(flight, now),
      'pickupAt': _iso(ride.pickupAt),
      'pickupAdjusted': flight.delay > Duration.zero && !flight.isDisrupted,
      if (flight.baseStatus == 'cancelled') 'cancellation': {'freeUntil': _iso(ride.pickupAt)},
      'serverTime': _iso(now),
    };
  }

  static List<Map<String, dynamic>> _events(_Flight flight, DateTime now) {
    final landedAt = flight.isDisrupted ? null : flight.estimated;
    final timed = <(String, DateTime?)>[
      ('landed', landedAt),
      ('baggage_claimed', landedAt?.add(_baggageAfter)),
      ('at_meet_point', landedAt?.add(_meetPointAfter)),
      ('met', null),
    ];
    final events = <Map<String, dynamic>>[
      {'type': 'scheduled_arrival', 'at': _iso(flight.scheduled), 'state': 'done'},
    ];
    var previousDone = true;
    for (final (type, time) in timed) {
      final isDone = time != null && !time.isAfter(now);
      final isPending = type == 'landed' ? false : !previousDone;
      events.add({
        'type': type,
        'at': isDone || type == 'landed' ? _isoOrNull(time) : null,
        'state': isDone
            ? 'done'
            : isPending || flight.isDisrupted
            ? 'pending'
            : 'current',
      });
      previousDone = isDone;
    }
    return events;
  }

  static String? _isoOrNull(DateTime? time) => time == null ? null : _iso(time);

  static Object? _notify(MockRequest request) {
    final ride = _requireRide(request);
    final now = DateTime.now();
    if (ride.flight.isDisrupted || ride.flight.estimated.isAfter(now)) {
      throw const MockFailure(409, 'Your flight hasn’t landed yet.', code: 'too_early');
    }
    ride.notifiedAt = now;
    return {'notifiedAt': _iso(now)};
  }

  static void _seed(DateTime start) {
    final tomorrow = DateTime(start.year, start.month, start.day + 1);
    final los = _airports[0];
    final abv = _airports[1];
    final plans = <_SeedPlan>[
      _SeedPlan(
        id: 'sched_air_1',
        code: 'BA',
        number: 75,
        destination: los,
        scheduled: _minute(start.add(const Duration(minutes: 3))),
        delay: Duration.zero,
        status: 'scheduled',
        pickupType: 'meet_greet',
        passengers: 2,
        luggageCount: 2,
        luggageSize: 'medium',
        category: 'plus',
        dropoff: {'name': 'Eko Hotel and Suites', 'address': 'Adetokunbo Ademola Street, Victoria Island, Lagos'},
        fare: 9500,
      ),
      _SeedPlan(
        id: 'sched_air_2',
        code: 'P4',
        number: 7129,
        destination: abv,
        scheduled: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14),
        delay: _delay,
        status: 'delayed',
        pickupType: 'arrival_zone',
        passengers: 1,
        luggageCount: 1,
        luggageSize: 'small',
        category: 'go',
        dropoff: {'name': 'Wuse 2', 'address': 'Wuse 2, Abuja, FCT'},
        fare: 7200,
      ),
      _SeedPlan(
        id: 'sched_air_3',
        code: 'VS',
        number: 408,
        destination: los,
        scheduled: DateTime(tomorrow.year, tomorrow.month, tomorrow.day + 1, 9, 30),
        delay: Duration.zero,
        status: 'cancelled',
        pickupType: 'arrival_zone',
        passengers: 3,
        luggageCount: 3,
        luggageSize: 'large',
        category: 'xl',
        dropoff: {'name': 'Lekki Phase 1', 'address': 'Lekki Phase 1, Lagos'},
        fare: 11800,
      ),
      _SeedPlan(
        id: 'sched_air_4',
        code: 'TK',
        number: 617,
        destination: los,
        scheduled: DateTime(tomorrow.year, tomorrow.month, tomorrow.day + 2, 22, 10),
        delay: Duration.zero,
        status: 'diverted',
        pickupType: 'meet_greet',
        passengers: 1,
        luggageCount: 1,
        luggageSize: 'medium',
        category: 'go',
        dropoff: {'name': 'Ikeja City Mall', 'address': 'Obafemi Awolowo Way, Ikeja, Lagos'},
        fare: 6900,
      ),
    ];
    for (final plan in plans) {
      final flight = _create(
        code: plan.code,
        number: plan.number,
        scheduled: plan.scheduled,
        destination: plan.destination,
        delay: plan.delay,
        baseStatus: plan.status == 'cancelled' || plan.status == 'diverted' ? plan.status : 'scheduled',
      );
      final lead = plan.pickupType == 'meet_greet' ? _meetGreetLead : _arrivalZoneLead;
      final pickupAt = flight.estimated.add(lead);
      _rides[plan.id] = _AirportRide(
        flight: flight,
        pickupAt: pickupAt,
        pickupType: plan.pickupType,
        passengers: plan.passengers,
        luggageCount: plan.luggageCount,
        luggageSize: plan.luggageSize,
        assistance: 'none',
      );
      _seeds.add(
        MockAirportSeed(
          id: plan.id,
          pickupAt: pickupAt,
          category: plan.category,
          pickup: {
            'name': '${flight.terminal['name']}, ${plan.destination['name']}',
            'address': '${plan.destination['city']}, ${plan.destination['country']}',
          },
          dropoff: plan.dropoff,
          fare: plan.fare,
        ),
      );
    }
  }
}

class _SeedPlan {
  const _SeedPlan({
    required this.id,
    required this.code,
    required this.number,
    required this.destination,
    required this.scheduled,
    required this.delay,
    required this.status,
    required this.pickupType,
    required this.passengers,
    required this.luggageCount,
    required this.luggageSize,
    required this.category,
    required this.dropoff,
    required this.fare,
  });

  final String id;
  final String code;
  final int number;
  final Map<String, dynamic> destination;
  final DateTime scheduled;
  final Duration delay;
  final String status;
  final String pickupType;
  final int passengers;
  final int luggageCount;
  final String luggageSize;
  final String category;
  final Map<String, dynamic> dropoff;
  final num fare;
}

class _Flight {
  _Flight({
    required this.id,
    required this.airline,
    required this.number,
    required this.origin,
    required this.destination,
    required this.destinationId,
    required this.scheduled,
    required this.delay,
    required this.terminal,
    required this.baseStatus,
  });

  final String id;
  final Map<String, dynamic> airline;
  final int number;
  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;
  final String destinationId;
  final DateTime scheduled;
  final Duration delay;
  final Map<String, dynamic> terminal;
  final String baseStatus;

  String get label => '${airline['code']} $number';

  DateTime get estimated => scheduled.add(delay);

  bool get isDisrupted => baseStatus == 'cancelled' || baseStatus == 'diverted';

  String statusAt(DateTime now) {
    if (isDisrupted) return baseStatus;
    if (!estimated.isAfter(now)) return 'landed';
    return delay > Duration.zero ? 'delayed' : 'scheduled';
  }

  Map<String, dynamic> json(DateTime now) => {
    'id': id,
    'airline': airline,
    'number': label,
    'origin': origin,
    'destination': destination,
    'scheduledArrival': MockAirport._iso(scheduled),
    'estimatedArrival': MockAirport._iso(estimated),
    'terminal': terminal,
    'status': statusAt(now),
  };
}

class _AirportRide {
  _AirportRide({
    required this.flight,
    required this.pickupAt,
    required this.pickupType,
    required this.passengers,
    required this.luggageCount,
    required this.luggageSize,
    required this.assistance,
  });

  final _Flight flight;
  final DateTime pickupAt;
  final String pickupType;
  final int passengers;
  final int luggageCount;
  final String luggageSize;
  final String assistance;
  DateTime? notifiedAt;

  String get luggageLabel {
    if (luggageCount == 0) return 'No luggage';
    return '$luggageCount $luggageSize ${luggageCount == 1 ? 'bag' : 'bags'}';
  }
}
