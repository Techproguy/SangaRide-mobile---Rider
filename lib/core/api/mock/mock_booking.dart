import 'package:sanga_ride/core/api/booking_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';

abstract final class MockBooking {
  static final List<MockRoute> routes = [
    MockRoute.get(BookingEndpoints.scheduledRides, (_) => {'rides': _rides.map(_payload).toList()}),
    MockRoute.post(BookingEndpoints.scheduledRides, _schedule),
    MockRoute.delete(BookingEndpoints.scheduledRide, _cancel),
    MockRoute.post(BookingEndpoints.scheduledRideReminder, _remind),
    MockRoute.get(BookingEndpoints.hourlyRates, (_) => hourlyRates),
    MockRoute.get(BookingEndpoints.cities, (_) => cities),
  ];

  static const Duration _reminderLead = Duration(minutes: 30);

  static const Map<String, dynamic> hourlyRates = {
    'minHours': 1,
    'maxHours': 12,
    'presets': [
      {'hours': 2, 'blurb': 'Good for short errands'},
      {'hours': 4, 'blurb': 'Ideal for meetings and events'},
      {'hours': 6, 'blurb': 'Suitable for multiple stops'},
      {'hours': 8, 'blurb': 'Full day flexibility'},
    ],
    'includes': ['Your driver and car for the whole time', 'Waiting time between stops', 'Fuel'],
    'excludes': ['Tolls and parking fees'],
    'rates': [
      {'category': 'go', 'hourlyRate': 6500},
      {'category': 'plus', 'hourlyRate': 8000},
      {'category': 'xl', 'hourlyRate': 11000},
      {'category': 'lux', 'hourlyRate': 18000},
      {'category': 'moto', 'hourlyRate': 2500},
      {'category': 'assist', 'hourlyRate': 11000},
    ],
  };

  static const Map<String, dynamic> cities = {
    'departureLeadMinutes': 120,
    'windowDays': 30,
    'cities': [
      {'id': 'lagos', 'name': 'Lagos', 'lat': 6.5244, 'lng': 3.3792, 'radiusKm': 45},
      {'id': 'ibadan', 'name': 'Ibadan', 'lat': 7.3775, 'lng': 3.9470, 'radiusKm': 25},
      {'id': 'abuja', 'name': 'Abuja', 'lat': 9.0765, 'lng': 7.3986, 'radiusKm': 40},
      {'id': 'benin', 'name': 'Benin', 'lat': 6.3350, 'lng': 5.6037, 'radiusKm': 25},
      {'id': 'port-harcourt', 'name': 'Port Harcourt', 'lat': 4.8156, 'lng': 7.0498, 'radiusKm': 30},
    ],
  };

  static final List<_ScheduledRecord> _rides = _seed();

  static int _nextId = 100;

  static List<_ScheduledRecord> _seed() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final ride = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
    return [
      _ScheduledRecord(
        id: 'sched_1',
        kind: 'one_time',
        tripType: 'oneWay',
        category: 'go',
        scheduledAt: ride,
        pickup: const {'name': 'Chicken Republic', 'address': 'Allen Avenue, Ikeja, Lagos'},
        dropoff: const {'name': 'Chicken Republic', 'address': 'Nnamdi Azikiwe Street, Idumota, Lagos'},
        fare: 4500,
      ),
      _ScheduledRecord(
        id: 'sched_2',
        kind: 'repeat',
        tripType: 'oneWay',
        category: 'plus',
        scheduledAt: ride.add(const Duration(days: 2, hours: -2)),
        pickup: const {'name': 'Lekki Phase 1', 'address': 'Lekki Phase 1, Lagos'},
        dropoff: const {'name': 'Ikeja City Mall', 'address': 'Obafemi Awolowo Way, Ikeja, Lagos'},
        fare: 6200,
        repeat: {
          'weekdays': [1, 3, 5],
          'time': '08:00',
          'startDate': _date(tomorrow),
          'endDate': null,
        },
      ),
    ];
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
      'scheduledAt': ride.scheduledAt.toUtc().toIso8601String(),
      'pickup': ride.pickup,
      'dropoff': ride.dropoff,
      'fare': ride.fare,
      'hours': ride.hours,
      'repeat': ride.repeat,
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

  static Object? _schedule(MockRequest request) {
    final body = request.body;
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
    final record = _ScheduledRecord(
      id: 'sched_${_nextId++}',
      kind: repeat == null ? 'one_time' : 'repeat',
      tripType: body['tripType'] as String,
      category: body['optionId'] as String,
      scheduledAt: scheduledAt,
      pickup: _stop(body['pickup']),
      dropoff: _stop(body['dropoff']),
      fare: (body['proposedFare'] as num?) ?? 0,
      hours: (body['hours'] as num?)?.toInt(),
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
