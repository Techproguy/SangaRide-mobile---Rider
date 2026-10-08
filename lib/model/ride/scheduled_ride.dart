import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';

enum ScheduledRideKind {
  oneTime('one_time'),
  repeat('repeat');

  const ScheduledRideKind(this.code);

  final String code;

  static ScheduledRideKind fromCode(String code) => values.firstWhere(
    (kind) => kind.code == code,
    orElse: () => throw FormatException('Unknown scheduled ride kind: $code'),
  );
}

class ScheduledStop {
  const ScheduledStop({required this.name, required this.address});

  factory ScheduledStop.fromJson(Map<String, dynamic> json) =>
      ScheduledStop(name: json['name'] as String, address: json['address'] as String);

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
  });

  factory ScheduledRide.fromJson(Map<String, dynamic> json) {
    final repeat = json['repeat'] as Map?;
    final reminderAt = json['reminderAt'] as String?;
    return ScheduledRide(
      id: json['id'] as String,
      kind: ScheduledRideKind.fromCode(json['kind'] as String),
      tripType: TripType.values.byName(json['tripType'] as String),
      category: RideCategory.values.byName(json['category'] as String),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
      pickup: ScheduledStop.fromJson(Map<String, dynamic>.from(json['pickup'] as Map)),
      dropoff: ScheduledStop.fromJson(Map<String, dynamic>.from(json['dropoff'] as Map)),
      fare: json['fare'] as num,
      canRemind: json['canRemind'] as bool,
      repeat: repeat == null ? null : RepeatRule.fromJson(Map<String, dynamic>.from(repeat)),
      hours: (json['hours'] as num?)?.toInt(),
      reminderAt: reminderAt == null ? null : DateTime.parse(reminderAt).toLocal(),
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
  const ScheduledFailed();
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
