import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/model/ride/ride_match.dart' show ScheduledBooking;
import 'package:sanga_ride/model/ride/ride_request.dart';

abstract final class BookingRules {
  static const Duration scheduleLeadTime = Duration(minutes: 15);
  static const Duration returnGap = Duration(minutes: 30);
  static const Duration bookingWindow = Duration(days: 30);
  static const int defaultHours = 2;
}

enum Weekday {
  monday('Monday', 'Mon'),
  tuesday('Tuesday', 'Tue'),
  wednesday('Wednesday', 'Wed'),
  thursday('Thursday', 'Thu'),
  friday('Friday', 'Fri'),
  saturday('Saturday', 'Sat'),
  sunday('Sunday', 'Sun');

  const Weekday(this.label, this.short);

  final String label;
  final String short;

  int get isoValue => index + 1;

  static Weekday fromIso(int value) => values[value - 1];
}

class RepeatRule {
  const RepeatRule({
    required this.weekdays,
    required this.hour,
    required this.minute,
    required this.startDate,
    this.endDate,
  });

  factory RepeatRule.fromJson(Map<String, dynamic> json) {
    final time = (json['time'] as String).split(':');
    final end = json['endDate'] as String?;
    return RepeatRule(
      weekdays: {for (final day in json['weekdays'] as List) Weekday.fromIso(day as int)},
      hour: int.parse(time[0]),
      minute: int.parse(time[1]),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: end == null ? null : DateTime.parse(end),
    );
  }

  static const Set<Weekday> _workWeek = {
    Weekday.monday,
    Weekday.tuesday,
    Weekday.wednesday,
    Weekday.thursday,
    Weekday.friday,
  };

  final Set<Weekday> weekdays;
  final int hour;
  final int minute;
  final DateTime startDate;
  final DateTime? endDate;

  List<Weekday> get _sorted => weekdays.toList()..sort((a, b) => a.index.compareTo(b.index));

  String get daysLabel {
    final days = _sorted;
    if (days.length == Weekday.values.length) return 'Every day';
    if (weekdays.length == _workWeek.length && weekdays.containsAll(_workWeek)) return 'Every weekday';
    if (days.length == 1) return 'Every ${days.first.label}';
    final names = [for (final day in days) day.short];
    return 'Every ${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  }

  DateTime get timeOfDay => DateTime(2000, 1, 1, hour, minute);

  DateTime? firstRideAfter(DateTime now) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final last = endDate == null ? null : DateTime(endDate!.year, endDate!.month, endDate!.day);
    for (var offset = 0; offset < 400; offset++) {
      final day = DateTime(start.year, start.month, start.day + offset);
      if (last != null && day.isAfter(last)) return null;
      final ride = DateTime(day.year, day.month, day.day, hour, minute);
      if (weekdays.contains(Weekday.fromIso(day.weekday)) && ride.isAfter(now)) return ride;
    }
    return null;
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
    'weekdays': [for (final day in _sorted) day.isoValue],
    'time': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    'startDate': _date(startDate),
    'endDate': endDate == null ? null : _date(endDate!),
  };
}

class City {
  const City({required this.id, required this.name, required this.coordinates, required this.radiusKm});

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'] as String,
    name: json['name'] as String,
    coordinates: LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble()),
    radiusKm: json['radiusKm'] as num,
  );

  final String id;
  final String name;
  final LatLng coordinates;
  final num radiusKm;

  bool covers(LatLng point) => coordinates.metersTo(point) <= radiusKm * 1000;

  static City? nearest(Iterable<City> cities, LatLng? point) {
    if (point == null) return null;
    final covering = cities.where((city) => city.covers(point)).toList()
      ..sort((a, b) => a.coordinates.metersTo(point).compareTo(b.coordinates.metersTo(point)));
    return covering.firstOrNull;
  }
}

enum IntercityIssue {
  unsupportedPickup('We don’t cover that pickup for intercity trips yet.'),
  unsupportedDropoff('We don’t cover that drop off for intercity trips yet.'),
  sameCity('Pick a drop off in a different city. For trips inside one city, use One way.');

  const IntercityIssue(this.message);

  final String message;
}

class HourlyPreset {
  const HourlyPreset({required this.hours, required this.blurb});

  factory HourlyPreset.fromJson(Map<String, dynamic> json) =>
      HourlyPreset(hours: (json['hours'] as num).toInt(), blurb: json['blurb'] as String);

  final int hours;
  final String blurb;
}

class HourlyCatalog {
  const HourlyCatalog({
    required this.rates,
    required this.minHours,
    required this.maxHours,
    required this.presets,
    required this.includes,
    required this.excludes,
  });

  factory HourlyCatalog.fromJson(Map<String, dynamic> json) => HourlyCatalog(
    rates: {
      for (final rate in json['rates'] as List)
        RideCategory.values.byName((rate as Map)['category'] as String): rate['hourlyRate'] as num,
    },
    minHours: (json['minHours'] as num).toInt(),
    maxHours: (json['maxHours'] as num).toInt(),
    presets: [
      for (final preset in json['presets'] as List) HourlyPreset.fromJson(Map<String, dynamic>.from(preset as Map)),
    ],
    includes: List<String>.from(json['includes'] as List),
    excludes: List<String>.from(json['excludes'] as List),
  );

  final Map<RideCategory, num> rates;
  final int minHours;
  final int maxHours;
  final List<HourlyPreset> presets;
  final List<String> includes;
  final List<String> excludes;

  num? rateFor(RideCategory? category) => category == null ? null : rates[category];

  bool isPreset(int hours) => presets.any((preset) => preset.hours == hours);
}

class IntercityCatalog {
  const IntercityCatalog({required this.cities, required this.departureLead, required this.bookingWindow});

  factory IntercityCatalog.fromJson(Map<String, dynamic> json) => IntercityCatalog(
    cities: [for (final city in json['cities'] as List) City.fromJson(Map<String, dynamic>.from(city as Map))],
    departureLead: Duration(minutes: (json['departureLeadMinutes'] as num).toInt()),
    bookingWindow: Duration(days: (json['windowDays'] as num).toInt()),
  );

  final List<City> cities;
  final Duration departureLead;
  final Duration bookingWindow;
}

class BookingCatalog {
  const BookingCatalog({required this.hourly, required this.intercity});

  final HourlyCatalog hourly;
  final IntercityCatalog intercity;
}

sealed class BookingCatalogState {
  const BookingCatalogState();
}

final class CatalogLoading extends BookingCatalogState {
  const CatalogLoading();
}

final class CatalogFailed extends BookingCatalogState {
  const CatalogFailed();
}

final class CatalogReady extends BookingCatalogState {
  const CatalogReady(this.catalog);

  final BookingCatalog catalog;
}

enum BookingProblem {
  scheduleTooSoon('schedule_too_soon', 'That time is too close. Pick a later one.'),
  intercityUnavailable('intercity_unavailable', 'We can’t do that intercity route yet.'),
  sameCity('same_city', 'Pick a drop off in a different city.'),
  reminderTooLate('reminder_too_late', 'This ride is too close for a reminder.'),
  tooEarly('too_early', 'Your flight hasn’t landed yet. You can notify your driver once it has.'),
  notFound('not_found', 'We can’t find that ride. It may already be gone.'),
  unknown('unknown', 'We couldn’t do that. Give it another go.');

  const BookingProblem(this.code, this.message);

  final String code;
  final String message;

  static BookingProblem fromCode(String? code) =>
      values.firstWhere((problem) => problem.code == code, orElse: () => unknown);
}

sealed class ScheduleOutcome {
  const ScheduleOutcome();
}

final class ScheduleSucceeded extends ScheduleOutcome {
  const ScheduleSucceeded(this.booking);

  final ScheduledBooking booking;
}

final class ScheduleRejected extends ScheduleOutcome {
  const ScheduleRejected(this.problem);

  final BookingProblem problem;
}
