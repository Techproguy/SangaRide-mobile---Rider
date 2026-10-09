import 'package:sanga_ride/model/ride/airport.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

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

  final String name;
  final String address;
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
  });

  factory ScheduledRide.fromJson(JsonReader json) {
    final airport = json.objectOrNull('airport');
    return ScheduledRide(
      id: json.str('id'),
      kind: ScheduledRideKind.fromCode(json.strOrNull('kind')),
      tripType: enumByCode(TripType.values, json.strOrNull('tripType'), (type) => type.name, TripType.oneWay),
      category: enumByCode(
        RideCategory.values,
        json.strOrNull('category'),
        (category) => category.name,
        RideCategory.go,
      ),
      scheduledAt: json.time('scheduledAt').toLocal(),
      pickup: ScheduledStop.fromJson(json.object('pickup')),
      dropoff: ScheduledStop.fromJson(json.object('dropoff')),
      fare: json.numOrNull('fare') ?? 0,
      canRemind: json.boolOr('canRemind', false),
      repeat: json.objectOrNull('repeat') == null ? null : RepeatRule.fromJson(json.object('repeat')),
      hours: json.intOrNull('hours'),
      reminderAt: json.timeOrNull('reminderAt')?.toLocal(),
      airport: airport == null ? null : ScheduledAirport.fromJson(airport.raw),
    );
  }

  final String id;
  final ScheduledRideKind kind;
  final TripType tripType;
  final RideCategory category;
  final DateTime scheduledAt;
  final ScheduledStop pickup;
  final ScheduledStop dropoff;
  final num fare;
  final bool canRemind;
  final RepeatRule? repeat;
  final int? hours;
  final DateTime? reminderAt;
  final ScheduledAirport? airport;

  bool get isRepeat => kind == ScheduledRideKind.repeat;

  bool get hasReminder => reminderAt != null;

  bool get showsRemindAction => canRemind && !hasReminder;
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
