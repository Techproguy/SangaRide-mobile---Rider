import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/api/error_handling.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/ride/airport.dart';
import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride/model/trip/scheduled_wait.dart';
import 'package:sanga_ride/model/trip/server_time.dart';
import 'package:sanga_ride/model/trip/trip_delivery.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum TripStatus {
  driverEnRoute('accepted'),
  driverArrived('driver_arrived'),
  pinVerified('pin_verified'),
  inProgress('in_progress'),
  arrivedDropoff('arrived_at_dropoff'),
  paymentPending('payment_pending'),
  completed('completed'),
  cancelled('cancelled'),
  unknown('unknown');

  const TripStatus(this.code);

  final String code;

  int get rank => this == unknown ? -1 : index;

  bool get isTerminal => this == completed || this == cancelled;

  bool get canChange => this == driverEnRoute || this == driverArrived || this == inProgress;

  static TripStatus ofRide(String? code, {required bool isPinVerified}) {
    final status = enumByCode(values, code, (status) => status.code, unknown);
    return status == driverArrived && isPinVerified ? pinVerified : status;
  }

  static TripStatus advance(TripStatus current, TripStatus incoming) {
    if (current.isTerminal) return current;
    if (incoming == unknown) return incoming;
    return incoming.rank > current.rank ? incoming : current;
  }
}

enum TripEventType {
  driverAccepted('driver_accepted', 'Driver accepted your request'),
  driverArrived('driver_arrived', 'Driver arrived at pickup'),
  detailsConfirmed('details_confirmed', 'You confirmed your driver’s details'),
  pinVerified('pin_verified', 'Driver confirmed your PIN'),
  tripStarted('trip_started', 'Trip started'),
  arrivedDropoff('arrived_dropoff', 'Arrived at drop off'),
  tripCompleted('trip_completed', 'Trip completed'),
  tripCancelled('trip_cancelled', 'Trip cancelled');

  const TripEventType(this.code, this.label);

  final String code;
  final String label;
}

class TripEvent {
  const TripEvent({required this.type, required this.at});

  final TripEventType type;
  final DateTime at;
}

enum TripIssue {
  driverNotSame('driver_not_same', 'Driver is not the same person'),
  vehicleDifferent('vehicle_different', 'Vehicle is different'),
  plateDifferent('plate_different', 'Plate number is different'),
  extraPayment('extra_payment', 'Driver asked for extra payment'),
  unsafe('unsafe', 'I feel unsafe'),
  other('other', 'Other');

  const TripIssue(this.code, this.label);

  final String code;
  final String label;
}

enum TripCancelReason {
  driverMismatch(
    'driver_mismatch',
    'Trip cancelled',
    'We’ve reported this and cancelled your trip. You won’t be charged.',
  ),
  driverCancelled('driver_cancelled', 'Your driver cancelled', 'Sorry about that. We won’t charge you.'),
  riderCancelled('rider_cancelled', 'Ride cancelled', 'You cancelled this ride.'),
  riderNoShow(
    'RIDER_NO_SHOW',
    'You missed your ride',
    'Your driver waited at the pickup but couldn’t find you, so the trip ended. A no show fee applies.',
  ),
  packageRefused('package_refused', 'Package not accepted', 'Your driver couldn’t take this package.'),
  deliveryCancelled('delivery_cancelled', 'Delivery cancelled', 'This delivery was cancelled.'),
  deliveryReturned(
    'delivery_returned',
    'Package returned',
    'Your driver couldn’t hand the package over, so they brought it back to the pickup.',
  ),
  other('other', 'Trip cancelled', 'This trip was cancelled. You won’t be charged.');

  const TripCancelReason(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  bool get offersRematch => this == driverCancelled;

  bool get didNotHappen => this == driverCancelled || this == packageRefused || this == deliveryCancelled;

  static TripCancelReason fromCode(String? code) => codedEnum(values, (reason) => reason.code, code, orElse: other);

  static TripCancelReason? tryFromCode(String? code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    return null;
  }

  static TripCancelReason? ofCancelledBy(String? who) => switch (who) {
    null => null,
    'rider' => riderCancelled,
    'driver' => driverCancelled,
    _ => other,
  };
}

enum TripLoadFailure {
  notFound('We can’t find this trip', 'It may have ended. Head back home to see what’s next.', canRetry: false),
  connection('We couldn’t load your trip', CommonCopy.connectionBody, canRetry: true),
  unknown(CommonCopy.serverTitle, CommonCopy.serverTrouble, canRetry: true);

  const TripLoadFailure(this.title, this.message, {required this.canRetry});

  final String title;
  final String message;
  final bool canRetry;

  static TripLoadFailure of(Object error) {
    if (error is ApiException && error.isGone) return notFound;
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => connection,
      _ => unknown,
    };
  }
}

enum StopStatus {
  reached('reached'),
  pending('pending'),
  unknown('unknown');

  const StopStatus(this.code);

  final String code;

  static StopStatus fromCode(String? code) => codedEnum(values, (status) => status.code, code, orElse: unknown);
}

LatLng _positionOf(JsonReader json) {
  final coordinates = json.objectOrNull('coordinates') ?? json;
  final latitude = coordinates.numOrNull('latitude') ?? coordinates.number('lat');
  final longitude = coordinates.numOrNull('longitude') ?? coordinates.number('lng');
  return LatLng(latitude.toDouble(), longitude.toDouble());
}

DateTime? _localTime(JsonReader json, String key) => json.timeOrNull(key)?.toLocal();

class TripPlace {
  const TripPlace({required this.name, required this.address, required this.position, this.isReached = false});

  factory TripPlace.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final address = reader.strOr('address', '');
    return TripPlace(
      name: reader.strOr('name', address),
      address: address,
      position: _positionOf(reader),
      isReached:
          StopStatus.fromCode(reader.strOrNull('status')) == StopStatus.reached ||
          reader.has('reachedAt') ||
          reader.has('arrivedAt'),
    );
  }

  final String name;
  final String address;
  final LatLng position;
  final bool isReached;

  Place toPlace() => Place(placeId: '', name: name, address: address, coordinates: position);

  String get title => toPlace().title;
}

class TripFare {
  const TripFare({required this.total, this.counterOffer});

  factory TripFare.fromJson(JsonReader json) => TripFare(
    total: json.moneyOrNull('finalFare') ?? json.moneyOrNull('agreedFare') ?? json.moneyOr('riderFare', Money.zero()),
  );

  final Money total;
  final Money? counterOffer;
}

class DriverPosition {
  const DriverPosition({required this.position, required this.heading});

  final LatLng position;
  final double? heading;
}

class Trip {
  const Trip({
    required this.id,
    required this.status,
    required this.rideType,
    required this.driver,
    required this.vehicle,
    required this.pickup,
    required this.stops,
    required this.dropoff,
    required this.fare,
    required this.pin,
    required this.pinExpiresAt,
    required this.events,
    required this.cancellationReason,
    this.etaAt,
    this.distanceRemainingKm,
    this.driverPosition,
    this.unreadMessages = 0,
    this.cancellationMessage,
    this.waitingFee,
    this.returnFee,
    this.airport,
    this.delivery,
    this.freeWait = Duration.zero,
    this.scheduledWait,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final pin = JsonReader.of(reader.raw['pin']);
    final isPinVerified = pin.boolOr('verified', false);
    final status = TripStatus.ofRide(reader.strOrNull('status'), isPinVerified: isPinVerified);
    final driver = JsonReader.of(reader.raw['driver']);
    final waiting = reader.objectOrNull('waiting');
    return Trip(
      id: reader.str('id'),
      status: status,
      rideType:
          RideCategory.values.asNameMap()[JsonReader.of(reader.raw['rideClass']).strOrNull('code')] ?? RideCategory.go,
      driver: OfferDriver.fromJson(driver.raw),
      vehicle: DriverVehicle.fromJson(driver.raw['vehicle']),
      pickup: TripPlace.fromJson(reader.object('pickup').raw),
      stops: reader.listOf('stops', (item) => TripPlace.fromJson(item.raw)),
      dropoff: TripPlace.fromJson(reader.object('dropoff').raw),
      fare: TripFare.fromJson(reader),
      pin: null,
      pinExpiresAt: deviceDeadlineOrNull(pin.strOrNull('expiresAt')),
      events: _eventsOf(
        JsonReader.of(reader.raw['timestamps']),
        status: status,
        isPinIssued: pin.has('expiresAt'),
        isPinVerified: isPinVerified,
      ),
      cancellationReason: _cancelReasonOf(reader, status),
      waitingFee: reader.moneyOrNull('waitingFee'),
      returnFee: reader.moneyOrNull('returnFee'),
      airport: reader.objectOrNull('airport') == null
          ? null
          : _tryRead(() => TripAirport.fromJson(reader.object('airport').raw)),
      delivery: reader.objectOrNull('delivery') == null
          ? null
          : _tryRead(() => TripDelivery.fromJson(reader.object('delivery').raw)),
      freeWait: Duration(seconds: waiting?.intOr('freeWaitSeconds', 0) ?? 0),
      scheduledWait: ScheduledWait.maybeFrom(waiting ?? reader, pickupAt: _localTime(reader, 'scheduledFor')),
    );
  }

  static bool isRideShape(Map<String, dynamic> json) =>
      json['id'] is String && json['status'] is String && json['pickup'] is Map && json['dropoff'] is Map;

  static T? _tryRead<T>(T Function() parse) {
    try {
      return parse();
    } catch (_) {
      return null;
    }
  }

  static TripCancelReason? _cancelReasonOf(JsonReader json, TripStatus status) {
    if (status != TripStatus.cancelled) return null;
    final isNoShow = (json.numOrNull('noShowFee') ?? 0) > 0;
    return TripCancelReason.tryFromCode(json.strOrNull('cancellationReasonCode')) ??
        TripCancelReason.tryFromCode(json.strOrNull('cancellationReason')) ??
        (isNoShow ? TripCancelReason.riderNoShow : null) ??
        TripCancelReason.ofCancelledBy(json.strOrNull('cancelledBy'));
  }

  static List<TripEvent> _eventsOf(
    JsonReader times, {
    required TripStatus status,
    required bool isPinIssued,
    required bool isPinVerified,
  }) {
    final accepted = _localTime(times, 'acceptedAt');
    final arrived = _localTime(times, 'arrivedAt');
    final passengerArrived = _localTime(times, 'passengerArrivedAt');
    final started = _localTime(times, 'startedAt');
    final confirmedAt = passengerArrived ?? arrived ?? accepted ?? DateTime.now();
    final candidates = <(TripEventType, DateTime?)>[
      (TripEventType.driverAccepted, accepted),
      (TripEventType.driverArrived, arrived),
      (TripEventType.detailsConfirmed, isPinIssued || isPinVerified ? confirmedAt : null),
      (TripEventType.pinVerified, isPinVerified ? started ?? confirmedAt : null),
      (TripEventType.tripStarted, started),
      (TripEventType.arrivedDropoff, _localTime(times, 'arrivedDropoffAt')),
      (TripEventType.tripCompleted, _localTime(times, 'completedAt')),
      (TripEventType.tripCancelled, status == TripStatus.cancelled ? _localTime(times, 'cancelledAt') : null),
    ];
    return [
      for (final (type, at) in candidates)
        if (at != null) TripEvent(type: type, at: at),
    ];
  }

  final String id;
  final TripStatus status;
  final RideCategory rideType;
  final OfferDriver driver;
  final DriverVehicle vehicle;
  final TripPlace pickup;
  final List<TripPlace> stops;
  final TripPlace dropoff;
  final TripFare fare;
  final String? pin;
  final DateTime? pinExpiresAt;
  final DateTime? etaAt;
  final double? distanceRemainingKm;
  final DriverPosition? driverPosition;
  final int unreadMessages;
  final List<TripEvent> events;
  final TripCancelReason? cancellationReason;
  final String? cancellationMessage;
  final Money? waitingFee;
  final Money? returnFee;
  final TripAirport? airport;
  final TripDelivery? delivery;
  final Duration freeWait;
  final ScheduledWait? scheduledWait;

  Trip withLocal({
    String? pin,
    DateTime? pinExpiresAt,
    DateTime? detailsConfirmedAt,
    TripCancelReason? cancellationReason,
    DriverPosition? livePosition,
  }) {
    final needsConfirmedEvent = detailsConfirmedAt != null && !hasEvent(TripEventType.detailsConfirmed);
    return Trip(
      id: id,
      status: status,
      rideType: rideType,
      driver: driver,
      vehicle: vehicle,
      pickup: pickup,
      stops: stops,
      dropoff: dropoff,
      fare: fare,
      pin: pin ?? this.pin,
      pinExpiresAt: pinExpiresAt ?? this.pinExpiresAt,
      events: needsConfirmedEvent
          ? [...events, TripEvent(type: TripEventType.detailsConfirmed, at: detailsConfirmedAt)]
          : events,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      etaAt: etaAt,
      distanceRemainingKm: distanceRemainingKm,
      driverPosition: livePosition ?? driverPosition,
      unreadMessages: unreadMessages,
      cancellationMessage: cancellationMessage,
      waitingFee: waitingFee,
      returnFee: returnFee,
      airport: airport,
      delivery: delivery,
      freeWait: freeWait,
      scheduledWait: scheduledWait,
    );
  }

  static const int maxStops = 3;

  List<TripPlace> get route => [pickup, ...stops, dropoff];

  bool get isDelivery => delivery != null;

  bool get canChange => status.canChange && (delivery?.stage.canCancel ?? true);

  bool get canAddStops => !isDelivery && canChange && stops.length < maxStops;

  DeliveryPhase? get deliveryPhase {
    final delivery = this.delivery;
    if (delivery == null || delivery.stage == DeliveryStage.refused || delivery.stage == DeliveryStage.returned) {
      return null;
    }
    if (delivery.stage == DeliveryStage.returning) return DeliveryPhase.returning;
    return switch (status) {
      TripStatus.driverEnRoute => DeliveryPhase.heading,
      TripStatus.driverArrived => pin == null ? DeliveryPhase.atPickup : DeliveryPhase.sharingPin,
      TripStatus.pinVerified => DeliveryPhase.afterPin(delivery),
      TripStatus.inProgress => DeliveryPhase.onTheWay,
      TripStatus.arrivedDropoff || TripStatus.paymentPending => DeliveryPhase.atDropoffOf(delivery.stage),
      TripStatus.completed || TripStatus.cancelled || TripStatus.unknown => null,
    };
  }

  static const double _unknownLegProgress = 0.5;
  static const double _minLegProgress = 0.1;
  static const double _maxLegProgress = 0.9;

  double get legProgress {
    if (status != TripStatus.inProgress) return 0;
    final remaining = distanceRemainingKm;
    final legStart = stops.lastWhere((stop) => stop.isReached, orElse: () => pickup);
    final legEnd = stops.firstWhere((stop) => !stop.isReached, orElse: () => dropoff);
    final legKm = legStart.position.metersTo(legEnd.position) / 1000;
    if (remaining == null || legKm <= 0) return _unknownLegProgress;
    return (1 - remaining / legKm).clamp(_minLegProgress, _maxLegProgress);
  }

  int? get nextStopNumber {
    final index = stops.indexWhere((stop) => !stop.isReached);
    return index < 0 ? null : index + 1;
  }

  bool hasEvent(TripEventType type) => events.any((event) => event.type == type);

  DateTime? eventTime(TripEventType type) {
    for (final event in events) {
      if (event.type == type) return event.at;
    }
    return null;
  }
}

sealed class TripState {
  const TripState();

  factory TripState.of(Trip trip) {
    final refusal = trip.delivery?.refusal;
    if (trip.delivery?.stage == DeliveryStage.refused && refusal != null) return TripRefused(trip, refusal);
    if (trip.delivery?.stage == DeliveryStage.returned) return TripReturned(trip);
    return _byStatus(trip);
  }

  static TripState _byStatus(Trip trip) => switch (trip.status) {
    TripStatus.driverEnRoute => TripEnRoute(trip),
    TripStatus.driverArrived => trip.pin == null ? TripArrived(trip) : TripVerifying(trip),
    TripStatus.pinVerified => TripAuthenticated(trip),
    TripStatus.inProgress => TripInProgress(trip),
    TripStatus.arrivedDropoff || TripStatus.paymentPending => TripAtDropoff(trip),
    TripStatus.completed => TripCompleted(trip),
    TripStatus.cancelled => TripCancelled(trip, trip.cancellationReason ?? TripCancelReason.other),
    TripStatus.unknown => TripUpdating(trip),
  };
}

final class TripLoading extends TripState {
  const TripLoading();
}

final class TripFailed extends TripState {
  const TripFailed(this.reason);

  final TripLoadFailure reason;
}

sealed class TripLoaded extends TripState {
  const TripLoaded(this.trip);

  final Trip trip;
}

final class TripUpdating extends TripLoaded {
  const TripUpdating(super.trip);
}

final class TripEnRoute extends TripLoaded {
  const TripEnRoute(super.trip);
}

final class TripArrived extends TripLoaded {
  const TripArrived(super.trip);
}

final class TripVerifying extends TripLoaded {
  const TripVerifying(super.trip);
}

final class TripAuthenticated extends TripLoaded {
  const TripAuthenticated(super.trip);
}

final class TripInProgress extends TripLoaded {
  const TripInProgress(super.trip);
}

final class TripAtDropoff extends TripLoaded {
  const TripAtDropoff(super.trip);
}

final class TripCompleted extends TripLoaded {
  const TripCompleted(super.trip);
}

final class TripCancelled extends TripLoaded {
  const TripCancelled(super.trip, this.reason);

  final TripCancelReason reason;
}

final class TripRefused extends TripLoaded {
  const TripRefused(super.trip, this.refusal);

  final DeliveryRefusal refusal;
}

final class TripReturned extends TripLoaded {
  const TripReturned(super.trip);
}
