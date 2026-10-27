import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride/model/ride/airport.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride/model/trip/scheduled_wait.dart';
import 'package:sanga_ride/model/trip/trip.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum ScheduledRideKind {
  oneTime('one_time'),
  repeat('repeat');

  const ScheduledRideKind(this.code);

  final String code;

  static ScheduledRideKind fromCode(String? code) => enumByCode(values, code, (kind) => kind.code, oneTime);
}

class ScheduledStop {
  const ScheduledStop({required this.name, required this.address});

  factory ScheduledStop.fromJson(JsonReader json) =>
      ScheduledStop(name: json.strOr('name', ''), address: json.strOr('address', ''));

  factory ScheduledStop.fromRide(JsonReader json) {
    final address = json.strOr('address', '');
    return ScheduledStop(name: json.strOrNull('name') ?? address, address: address);
  }

  final String name;
  final String address;

  bool get _isNamedByAddress => name.trim().isEmpty || name.trim() == address.trim();

  List<String> get _addressParts => [
    for (final part in address.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];

  String get title => _isNamedByAddress ? (_addressParts.firstOrNull ?? address) : name;

  String get subtitle => _isNamedByAddress ? _addressParts.skip(1).join(', ') : address;
}

class ScheduledRide {
  const ScheduledRide({
    required this.id,
    required this.kind,
    required this.tripType,
    required this.category,
    required this.scheduledAt,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.canRemind,
    this.repeat,
    this.hours,
    this.reminderAt,
    this.airport,
    this.wait,
  });

  factory ScheduledRide.fromJson(JsonReader json) {
    final airport = json.objectOrNull('airport');
    final scheduledAt = json.time('scheduledFor').toLocal();
    return ScheduledRide(
      id: json.str('id'),
      kind: ScheduledRideKind.fromCode(json.strOrNull('kind')),
      tripType: TripType.fromCode(json.strOrNull('tripType')),
      category: enumByCode(
        RideCategory.values,
        json.strOrNull('category'),
        (category) => category.name,
        RideCategory.go,
      ),
      scheduledAt: scheduledAt,
      pickup: ScheduledStop.fromJson(json.object('pickup')),
      dropoff: ScheduledStop.fromJson(json.object('dropoff')),
      fare: json.money('fare'),
      canRemind: json.boolOr('canRemind', false),
      repeat: json.objectOrNull('repeat') == null ? null : RepeatRule.fromJson(json.object('repeat')),
      hours: json.intOrNull('hours'),
      reminderAt: json.timeOrNull('reminderAt')?.toLocal(),
      airport: airport == null ? null : ScheduledAirport.fromJson(airport.raw),
      wait: ScheduledWait.maybeFrom(json, pickupAt: scheduledAt),
    );
  }

  factory ScheduledRide.fromRide(JsonReader json) {
    final airport = json.objectOrNull('airport');
    final scheduledAt = json.time('scheduledFor').toLocal();
    final hourlyMinutes = json.intOrNull('hourlyDurationMin');
    return ScheduledRide(
      id: json.str('id'),
      kind: ScheduledRideKind.oneTime,
      tripType: TripType.fromCode(json.strOrNull('tripType')),
      category: enumByCode(
        RideCategory.values,
        json.objectOrNull('rideClass')?.strOrNull('code'),
        (category) => category.name,
        RideCategory.go,
      ),
      scheduledAt: scheduledAt,
      pickup: ScheduledStop.fromRide(json.object('pickup')),
      dropoff: ScheduledStop.fromRide(json.object('dropoff')),
      fare: TripFare.fromJson(json).total,
      canRemind: json.boolOr('canRemind', true),
      reminderAt: (json.timeOrNull('reminderAt') ?? json.timeOrNull('reminderSentAt'))?.toLocal(),
      hours: hourlyMinutes == null ? null : hourlyMinutes ~/ Duration.minutesPerHour,
      airport: airport?.timeOrNull('estimatedArrival') == null ? null : ScheduledAirport.fromJson(airport!.raw),
      wait: ScheduledWait.maybeFrom(json.objectOrNull('waiting') ?? json, pickupAt: scheduledAt),
    );
  }

  static const Duration reminderLead = Duration(minutes: 30);

  final String id;
  final ScheduledRideKind kind;
  final TripType tripType;
  final RideCategory category;
  final DateTime scheduledAt;
  final ScheduledStop pickup;
  final ScheduledStop dropoff;
  final Money fare;
  final bool canRemind;
  final RepeatRule? repeat;
  final int? hours;
  final DateTime? reminderAt;
  final ScheduledAirport? airport;
  final ScheduledWait? wait;

  bool get isRepeat => kind == ScheduledRideKind.repeat;

  bool get hasReminder => reminderAt != null;

  bool get showsRemindAction =>
      canRemind && !hasReminder && scheduledAt.subtract(reminderLead).isAfter(BookingClock.now());

  ScheduledRide withReminder(DateTime at) => ScheduledRide(
    id: id,
    kind: kind,
    tripType: tripType,
    category: category,
    scheduledAt: scheduledAt,
    pickup: pickup,
    dropoff: dropoff,
    fare: fare,
    canRemind: canRemind,
    repeat: repeat,
    hours: hours,
    reminderAt: at,
    airport: airport,
    wait: wait,
  );
}

sealed class ScheduledRidesState {
  const ScheduledRidesState();
}

final class ScheduledLoading extends ScheduledRidesState {
  const ScheduledLoading();
}

final class ScheduledFailed extends ScheduledRidesState {
  const ScheduledFailed({this.problem = RideLoadProblem.connection});

  final RideLoadProblem problem;
}

enum ScheduledAction { cancel, remind }

final class ScheduledLoaded extends ScheduledRidesState {
  const ScheduledLoaded(this.rides, {this.busy = const {}});

  final List<ScheduledRide> rides;
  final Map<String, ScheduledAction> busy;

  ScheduledAction? actionOn(String id) => busy[id];

  ScheduledLoaded copyWith({List<ScheduledRide>? rides, Map<String, ScheduledAction>? busy}) =>
      ScheduledLoaded(rides ?? this.rides, busy: busy ?? this.busy);
}
