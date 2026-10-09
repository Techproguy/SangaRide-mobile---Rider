import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/ride/flight.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

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

  static FlightEventState fromCode(String? code) => codedEnum(values, (state) => state.code, code, orElse: pending);
}

class FlightEvent {
  const FlightEvent({required this.type, required this.state, this.at});

  static FlightEvent? tryParse(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    final type = FlightEventType.fromCode(json.strOrNull('type'));
    if (type == null) return null;
    return FlightEvent(
      type: type,
      state: FlightEventState.fromCode(json.strOrNull('state')),
      at: json.has('at') ? json.time('at').toLocal() : null,
    );
  }

  final FlightEventType type;
  final FlightEventState state;
  final DateTime? at;
}

class FlightCancellation {
  const FlightCancellation({required this.freeUntil});

  factory FlightCancellation.fromJson(Map<String, dynamic> raw) =>
      FlightCancellation(freeUntil: JsonReader(raw).time('freeUntil').toLocal());

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

  factory FlightTracking.fromJson(Map<String, dynamic> raw) {
    final json = JsonReader(raw);
    final cancellation = json.objectOrNull('cancellation');
    return FlightTracking(
      flight: Flight.fromJson(json.object('flight').raw),
      events: [
        for (final event in json.listOf<FlightEvent?>('events', (item) => FlightEvent.tryParse(item.raw))) ?event,
      ],
      pickupAt: json.time('pickupAt').toLocal(),
      pickupAdjusted: json.boolOr('pickupAdjusted', false),
      cancellation: cancellation == null ? null : FlightCancellation.fromJson(cancellation.raw),
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
  connection('We couldn’t load your flight', CommonCopy.connectionBody, canRetry: true),
  unknown('We couldn’t load your flight', CommonCopy.serverTrouble, canRetry: true);

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
