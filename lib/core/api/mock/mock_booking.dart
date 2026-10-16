import 'package:sanga_ride/core/api/booking_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_airport.dart';
import 'package:sanga_ride/core/api/mock/mock_money.dart';
import 'package:sanga_ride/core/api/mock/mock_region.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';

abstract final class MockBooking {
  static final List<MockRoute> routes = [
    MockRoute.get(BookingEndpoints.scheduledRides, (_) => {'rides': _rides.map(_payload).toList()}),
    MockRoute.delete(BookingEndpoints.scheduledRide, _cancel),
    MockRoute.post(BookingEndpoints.scheduledRideReminder, _remind),
    MockRoute.get(BookingEndpoints.hourlyTiers, _hourlyTiers),
    MockRoute.get(BookingEndpoints.cities, (_) => cities),
    MockRoute.get(BookingEndpoints.rules, (_) => rules),
  ];

  static const Duration _reminderLead = Duration(minutes: 30);
  static const int _defaultFreeWaitSeconds = 300;
  static const Map<String, int> _freeWaitSecondsByCategory = {'lux': 900};
  static const Duration _arriveEarly = Duration(minutes: 15);
  static const Duration _airportArriveEarly = Duration(minutes: 30);
  static const Duration _scheduledFreeWait = Duration(minutes: 30);
  static const int _waitingFeePerMinute = 100;

  static int freeWaitSeconds(String category) => _freeWaitSecondsByCategory[category] ?? _defaultFreeWaitSeconds;

  static Map<String, dynamic> scheduledWaitJson(DateTime pickupAt, {required bool isAirport}) => {
    'arriveByAt': pickupAt.subtract(isAirport ? _airportArriveEarly : _arriveEarly).toUtc().toIso8601String(),
    'freeWaitUntil': pickupAt.add(_scheduledFreeWait).toUtc().toIso8601String(),
    'waitingFeePerMinute': MockMoney.json(_waitingFeePerMinute),
  };

  static const Map<String, dynamic> rules = {'scheduleLeadMinutes': 15, 'returnGapMinutes': 30, 'windowDays': 30};

  static Object? _hourlyTiers(MockRequest request) {
    final code = request.params['code'];
    final rate = hourlyRatesNaira.where((rate) => rate['category'] == code).firstOrNull?['hourlyRate'] as num?;
    if (rate == null) throw const MockFailure(404, 'We can’t find that ride class.', code: 'not_found');
    return {
      'tiers': [
        for (final tier in _hourlyPresets)
          {
            'durationMin': (tier['hours'] as int) * Duration.minutesPerHour,
            'label': '${tier['hours']} hours',
            'sublabel': tier['blurb'],
            'price': MockMoney.of(rate * (tier['hours'] as int)).major,
          },
      ],
      'custom': {
        'enabled': true,
        'minMin': _minHourlyMinutes,
        'maxMin': _maxHourlyMinutes,
        'perHour': MockMoney.of(rate).major,
      },
    };
  }

  static const int _minHourlyMinutes = 60;
  static const int _maxHourlyMinutes = 720;

  static const List<Map<String, Object>> _hourlyPresets = [
    {'hours': 2, 'blurb': 'Good for short errands'},
    {'hours': 4, 'blurb': 'Ideal for meetings and events'},
    {'hours': 6, 'blurb': 'Suitable for multiple stops'},
    {'hours': 8, 'blurb': 'Full day flexibility'},
  ];

  static const List<Map<String, dynamic>> hourlyRatesNaira = [
    {'category': 'go', 'hourlyRate': 6500},
    {'category': 'plus', 'hourlyRate': 8000},
    {'category': 'xl', 'hourlyRate': 11000},
    {'category': 'lux', 'hourlyRate': 18000},
    {'category': 'moto', 'hourlyRate': 2500},
    {'category': 'assist', 'hourlyRate': 11000},
  ];

  static Map<String, dynamic> get cities => {
    'departureLeadMinutes': 120,
    'windowDays': 30,
    'cities': MockRegion.isUnitedStates ? _unitedStatesCities : _nigerianCities,
  };

  static const List<Map<String, dynamic>> _nigerianCities = [
    {'id': 'lagos', 'name': 'Lagos', 'lat': 6.5244, 'lng': 3.3792, 'radiusKm': 45},
    {'id': 'ibadan', 'name': 'Ibadan', 'lat': 7.3775, 'lng': 3.9470, 'radiusKm': 25},
    {'id': 'abuja', 'name': 'Abuja', 'lat': 9.0765, 'lng': 7.3986, 'radiusKm': 40},
    {'id': 'benin', 'name': 'Benin', 'lat': 6.3350, 'lng': 5.6037, 'radiusKm': 25},
    {'id': 'port-harcourt', 'name': 'Port Harcourt', 'lat': 4.8156, 'lng': 7.0498, 'radiusKm': 30},
  ];

  static const List<Map<String, dynamic>> _unitedStatesCities = [
    {'id': 'houston', 'name': 'Houston', 'lat': 29.7604, 'lng': -95.3698, 'radiusKm': 45},
    {'id': 'austin', 'name': 'Austin', 'lat': 30.2672, 'lng': -97.7431, 'radiusKm': 25},
    {'id': 'dallas', 'name': 'Dallas', 'lat': 32.7767, 'lng': -96.7970, 'radiusKm': 40},
    {'id': 'san-antonio', 'name': 'San Antonio', 'lat': 29.4241, 'lng': -98.4936, 'radiusKm': 25},
    {'id': 'galveston', 'name': 'Galveston', 'lat': 29.3013, 'lng': -94.7977, 'radiusKm': 30},
  ];

  static final List<_ScheduledRecord> _rides = _seed();

  static int _nextId = 100;

  static List<_ScheduledRecord> _seed() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final ride = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
    return [
      _ScheduledRecord(
        id: 'sched_1',
        kind: 'one_time',
        tripType: 'one_way',
        category: 'go',
        scheduledAt: ride,
        pickup: MockRegion.stop('mock_cr_ikeja'),
        dropoff: MockRegion.stop('mock_cr_idumota'),
        fare: 4500,
      ),
      _ScheduledRecord(
        id: 'sched_2',
        kind: 'repeat',
        tripType: 'one_way',
        category: 'plus',
        scheduledAt: ride.add(const Duration(days: 2, hours: -2)),
        pickup: MockRegion.stop('mock_lekki'),
        dropoff: MockRegion.stop('mock_icm'),
        fare: 6200,
        repeat: {
          'weekdays': [1, 3, 5],
          'time': '08:00',
          'startDate': _date(tomorrow),
          'endDate': null,
        },
      ),
      for (final seed in MockAirport.seeds)
        _ScheduledRecord(
          id: seed.id,
          kind: 'one_time',
          tripType: 'airport',
          category: seed.category,
          scheduledAt: seed.pickupAt,
          pickup: seed.pickup,
          dropoff: seed.dropoff,
          fare: seed.fare,
        ),
    ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  static Map<String, dynamic> scheduleAirport(Map<String, dynamic> body, MockAirportDecision decision) {
    final record = _ScheduledRecord(
      id: 'sched_${_nextId++}',
      kind: 'one_time',
      tripType: 'airport',
      category: body['optionId'] as String,
      scheduledAt: decision.pickupAt,
      pickup: _stop(body['pickup']),
      dropoff: _stop(body['dropoff']),
      fare: MockMoney.naira(body['proposedFare']),
    );
    MockAirport.register(record.id, body, decision.pickupAt);
    _rides.add(record);
    _rides.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return _payload(record);
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _payload(_ScheduledRecord ride) {
    final remindAt = ride.scheduledAt.subtract(_reminderLead);
    return {
      'id': ride.id,
      'status': 'scheduled',
      'kind': ride.kind,
      'tripType': ride.tripType,
      'category': ride.category,
      'scheduledFor': ride.scheduledAt.toUtc().toIso8601String(),
      ...scheduledWaitJson(ride.scheduledAt, isAirport: ride.tripType == 'airport'),
      'pickup': ride.pickup,
      'dropoff': ride.dropoff,
      'fare': MockMoney.json(ride.fare),
      'hours': ride.hours,
      'repeat': ride.repeat,
      'airport': ?MockAirport.display(ride.id),
      'reminderAt': ride.reminderAt?.toUtc().toIso8601String(),
      'canRemind': remindAt.isAfter(DateTime.now()),
      'serverTime': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static _ScheduledRecord _require(MockRequest request) {
    final ride = _rides.where((ride) => ride.id == request.params['id']).firstOrNull;
    if (ride == null) throw const MockFailure(404, 'We can’t find that ride.', code: 'not_found');
    return ride;
  }

  static Map<String, dynamic> _stop(Object? place) {
    final json = place as Map;
    return {'name': json['name'], 'address': json['address']};
  }

  static DateTime? _firstRide(Map<String, dynamic> repeat) {
    final time = (repeat['time'] as String).split(':');
    final start = DateTime.parse(repeat['startDate'] as String);
    final weekdays = List<int>.from(repeat['weekdays'] as List);
    final end = repeat['endDate'] == null ? null : DateTime.parse(repeat['endDate'] as String);
    for (var offset = 0; offset < 400; offset++) {
      final day = DateTime(start.year, start.month, start.day + offset);
      if (end != null && day.isAfter(end)) return null;
      final ride = DateTime(day.year, day.month, day.day, int.parse(time[0]), int.parse(time[1]));
      if (weekdays.contains(day.weekday) && ride.isAfter(DateTime.now())) return ride;
    }
    return null;
  }

  static Object? schedule(Map<String, dynamic> body) {
    final repeat = body['repeat'] == null ? null : Map<String, dynamic>.from(body['repeat'] as Map);
    final scheduledAt = repeat != null
        ? _firstRide(repeat)
        : DateTime.tryParse(body['scheduledAt'] as String? ?? '')?.toLocal();
    if (scheduledAt == null || scheduledAt.isBefore(DateTime.now().add(const Duration(minutes: 10)))) {
      throw const MockFailure(422, 'That time is too close.', code: 'schedule_too_soon');
    }
    if (body['tripType'] == 'intercity' && body['fromCityId'] == body['toCityId']) {
      throw const MockFailure(422, 'Pick different cities.', code: 'same_city');
    }
    final durationMinutes = (body['hourlyDurationMin'] as num?)?.toInt();
    final record = _ScheduledRecord(
      id: 'sched_${_nextId++}',
      kind: repeat == null ? 'one_time' : 'repeat',
      tripType: body['tripType'] as String,
      category: body['optionId'] as String,
      scheduledAt: scheduledAt,
      pickup: _stop(body['pickup']),
      dropoff: _stop(body['dropoff']),
      fare: MockMoney.naira(body['proposedFare']),
      hours: durationMinutes == null ? null : durationMinutes ~/ Duration.minutesPerHour,
      repeat: repeat,
    );
    _rides.add(record);
    _rides.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return _payload(record);
  }

  static Object? _cancel(MockRequest request) {
    _rides.remove(_require(request));
    return null;
  }

  static Object? _remind(MockRequest request) {
    final ride = _require(request);
    if (!ride.scheduledAt.subtract(_reminderLead).isAfter(DateTime.now())) {
      throw const MockFailure(422, 'This ride is too close for a reminder.', code: 'reminder_too_late');
    }
    ride.reminderAt = ride.scheduledAt.subtract(_reminderLead);
    return _payload(ride);
  }
}

class _ScheduledRecord {
  _ScheduledRecord({
    required this.id,
    required this.kind,
    required this.tripType,
    required this.category,
    required this.scheduledAt,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    this.hours,
    this.repeat,
  });

  final String id;
  final String kind;
  final String tripType;
  final String category;
  final DateTime scheduledAt;
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final num fare;
  final int? hours;
  final Map<String, dynamic>? repeat;
  DateTime? reminderAt;
}
