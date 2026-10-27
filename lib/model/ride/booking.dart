import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride/model/ride/ride_match.dart' show ScheduledBooking;
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class BookingRules {
  const BookingRules({required this.scheduleLeadTime, required this.returnGap, required this.bookingWindow});

  factory BookingRules.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return BookingRules(
      scheduleLeadTime: Duration(minutes: json.intOr('scheduleLeadMinutes', fallback.scheduleLeadTime.inMinutes)),
      returnGap: Duration(minutes: json.intOr('returnGapMinutes', fallback.returnGap.inMinutes)),
      bookingWindow: Duration(days: json.intOr('windowDays', fallback.bookingWindow.inDays)),
    );
  }

  static const BookingRules fallback = BookingRules(
    scheduleLeadTime: Duration(minutes: 15),
    returnGap: Duration(minutes: 30),
    bookingWindow: Duration(days: 30),
  );
  static const int defaultHours = 2;

  final Duration scheduleLeadTime;
  final Duration returnGap;
  final Duration bookingWindow;
}

abstract final class BookingClock {
  static DateTime now() => ServerClock.instance.now().toLocal();
}

abstract final class BookingZone {
  static Map<String, dynamic> of(DateTime at) => {
    'utcOffsetMinutes': at.timeZoneOffset.inMinutes,
    'name': at.timeZoneName,
  };
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

  static Weekday? tryFromIso(int value) => value >= 1 && value <= values.length ? values[value - 1] : null;

  static Weekday? tryFromName(String value) {
    final name = value.trim().toLowerCase();
    if (name.length < 3) return null;
    return values.where((day) => day.label.toLowerCase().startsWith(name.substring(0, 3))).firstOrNull;
  }

  static Weekday fromIso(int value) => tryFromIso(value) ?? (throw JsonFormatError('Unknown weekday', value));
}

class RepeatRule {
  const RepeatRule({
    required this.weekdays,
    required this.hour,
    required this.minute,
    required this.startDate,
    this.endDate,
  });

  factory RepeatRule.fromJson(JsonReader json) {
    final time = json.str('time').split(':');
    final days = json.raw['weekdays'] ?? json.raw['days'];
    return RepeatRule(
      weekdays: {
        for (final day in (days as List? ?? const []))
          if (day is num) ?Weekday.tryFromIso(day.toInt()) else if (day is String) ?Weekday.tryFromName(day),
      },
      hour: int.parse(time[0]),
      minute: int.parse(time[1]),
      startDate: json.timeOrNull('startDate') ?? DateTime.now(),
      endDate: json.timeOrNull('endDate'),
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
    'days': [for (final day in _sorted) day.short.toLowerCase()],
    'time': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    'startDate': _date(startDate),
    'endDate': ?(endDate == null ? null : _date(endDate!)),
    'timezone': BookingZone.of(DateTime(startDate.year, startDate.month, startDate.day, hour, minute)),
  };
}

class City {
  const City({required this.id, required this.name, required this.coordinates, required this.radiusKm});

  factory City.fromJson(JsonReader json) {
    final center = json.objectOrNull('center') ?? json;
    final radiusMeters = json.numOrNull('radiusMeters');
    return City(
      id: json.str('id'),
      name: json.str('name'),
      coordinates: LatLng(center.number('lat').toDouble(), center.number('lng').toDouble()),
      radiusKm: radiusMeters == null ? json.number('radiusKm') : radiusMeters / 1000,
    );
  }

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
  const HourlyPreset({required this.hours, required this.blurb, required this.price});

  factory HourlyPreset.fromJson(JsonReader json) {
    final minutes = json.integer('durationMin');
    if (minutes <= 0 || minutes % Duration.minutesPerHour != 0) {
      throw JsonFormatError('Expected a whole number of hours at "durationMin"', json.raw['durationMin']);
    }
    return HourlyPreset(
      hours: minutes ~/ Duration.minutesPerHour,
      blurb: json.strOr('sublabel', ''),
      price: json.money('price'),
    );
  }

  final int hours;
  final String blurb;
  final Money price;

  Money get perHour => Money((price.minor / hours).round(), price.currency);
}

class HourlyCatalog {
  const HourlyCatalog({
    required this.hourlyRate,
    required this.minHours,
    required this.maxHours,
    required this.presets,
    this.includes = const [],
    this.excludes = const [],
  });

  factory HourlyCatalog.fromJson(Object? body) {
    final json = JsonReader.of(body);
    final presets = json.listOf('tiers', HourlyPreset.fromJson);
    final custom = json.objectOrNull('custom');
    final isCustomEnabled = custom?.boolOr('enabled', false) ?? false;
    final firstPreset = presets.firstOrNull;
    final rate = custom?.moneyOrNull('perHour') ?? firstPreset?.perHour;
    return HourlyCatalog(
      hourlyRate: rate,
      minHours: isCustomEnabled
          ? (custom!.intOr('minMin', Duration.minutesPerHour) / Duration.minutesPerHour).ceil()
          : firstPreset?.hours ?? 1,
      maxHours: isCustomEnabled
          ? custom!.intOr('maxMin', 12 * Duration.minutesPerHour) ~/ Duration.minutesPerHour
          : presets.lastOrNull?.hours ?? 12,
      presets: presets,
    );
  }

  final Money? hourlyRate;
  final int minHours;
  final int maxHours;
  final List<HourlyPreset> presets;
  final List<String> includes;
  final List<String> excludes;

  bool isPreset(int hours) => presets.any((preset) => preset.hours == hours);
}

class IntercityCatalog {
  const IntercityCatalog({required this.cities, required this.departureLead, required this.bookingWindow});

  factory IntercityCatalog.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return IntercityCatalog(
      cities: json.listOf('cities', City.fromJson),
      departureLead: Duration(minutes: json.intOr('departureLeadMinutes', 120)),
      bookingWindow: Duration(days: json.intOr('windowDays', BookingRules.fallback.bookingWindow.inDays)),
    );
  }

  final List<City> cities;
  final Duration departureLead;
  final Duration bookingWindow;
}

class BookingCatalog {
  const BookingCatalog({required this.hourly, required this.intercity, required this.rules});

  final Map<RideCategory, HourlyCatalog> hourly;
  final IntercityCatalog intercity;
  final BookingRules rules;
}

sealed class BookingCatalogState {
  const BookingCatalogState();
}

final class CatalogLoading extends BookingCatalogState {
  const CatalogLoading();
}

final class CatalogFailed extends BookingCatalogState {
  const CatalogFailed(this.problem);

  final RideLoadProblem problem;
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
  quoteExpired(ServerCode.quoteExpired, 'Your price changed. Have a look at the new one, then go again.'),
  notFound(ServerCode.notFound, 'We can’t find that ride. It may already be gone.'),
  connection('connection', CommonCopy.offline),
  rejected('rejected', 'We couldn’t book that. Check your trip details and try again.'),
  unknown('unknown', CommonCopy.serverTrouble);

  const BookingProblem(this.code, this.message);

  final String code;
  final String message;

  static BookingProblem fromCode(String? code) => enumByCode(values, code, (problem) => problem.code, unknown);

  static BookingProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => switch (fromCode(code)) {
      unknown => rejected,
      final known => known,
    },
    _ => unknown,
  };
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

final class ScheduleUnconfirmed extends ScheduleOutcome {
  const ScheduleUnconfirmed();
}
