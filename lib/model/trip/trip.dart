import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/ride/airport.dart';
import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride/model/trip/server_time.dart';
import 'package:sanga_ride/model/trip/trip_delivery.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum TripStatus {
  driverEnRoute('driver_en_route'),
  driverArrived('driver_arrived'),
  pinVerified('pin_verified'),
  inProgress('in_progress'),
  arrivedDropoff('arrived_dropoff'),
  paymentPending('payment_pending'),
  completed('completed'),
  cancelled('cancelled'),
  unknown('unknown');

  const TripStatus(this.code);

  final String code;

  int get rank => this == unknown ? -1 : index;

  bool get isTerminal => this == completed || this == cancelled;

  bool get canChange => this == driverEnRoute || this == driverArrived || this == inProgress;

  static TripStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, unknown);

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

  static TripEventType? fromCode(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

class TripEvent {
  const TripEvent({required this.type, required this.at});

  static TripEvent? tryParse(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final type = TripEventType.fromCode(reader.strOrNull('type'));
    final at = reader.timeOrNull('at');
    if (type == null || at == null) return null;
    return TripEvent(type: type, at: at.toLocal());
  }

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

  static TripCancelReason fromCode(String? code) =>
      values.firstWhere((reason) => reason.code == code, orElse: () => other);
}

enum TripLoadFailure {
  notFound('We can’t find this trip', 'It may have ended. Head back home to see what’s next.', canRetry: false),
  connection('We couldn’t load your trip', 'Check your connection and give it another go.', canRetry: true),
  unknown('Something went wrong', 'Something went wrong on our side. Try again in a moment.', canRetry: true);

  const TripLoadFailure(this.title, this.message, {required this.canRetry});

  final String title;
  final String message;
  final bool canRetry;

  static TripLoadFailure of(Object error) {
    if (error is ApiException && (error.statusCode == 404 || error.statusCode == 410)) return notFound;
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => connection,
      _ => unknown,
    };
  }
}

LatLng _latLng(JsonReader json) => LatLng(json.number('lat').toDouble(), json.number('lng').toDouble());

class TripPlace {
  const TripPlace({required this.name, required this.address, required this.position, this.isReached = false});

  factory TripPlace.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return TripPlace(
      name: reader.str('name'),
      address: reader.strOr('address', ''),
      position: _latLng(reader.object('coordinates')),
      isReached: reader.strOrNull('status') == 'reached',
    );
  }

  final String name;
  final String address;
  final LatLng position;
  final bool isReached;

  Place toPlace() => Place(placeId: '', name: name, address: address, coordinates: position);
}

class TripFare {
  const TripFare({required this.total, required this.counterOffer});

  factory TripFare.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return TripFare(total: reader.integer('total'), counterOffer: reader.intOrNull('counterOffer'));
  }

  final int total;
  final int? counterOffer;
}

class DriverPosition {
  const DriverPosition({required this.position, required this.heading});

  factory DriverPosition.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return DriverPosition(position: _latLng(reader), heading: reader.doubleOrNull('heading'));
  }

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
    required this.etaAt,
    required this.distanceRemainingKm,
    required this.driverPosition,
    required this.unreadMessages,
    required this.events,
    required this.cancellationReason,
    this.cancellationMessage,
    this.returnFee,
    this.airport,
    this.delivery,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return Trip(
      id: reader.str('id'),
      status: TripStatus.fromCode(reader.strOrNull('status')),
      rideType: RideCategory.values.asNameMap()[reader.strOrNull('rideType')] ?? RideCategory.go,
      driver: OfferDriver.fromJson(reader.raw['driver']),
      vehicle: DriverVehicle.fromJson(reader.raw['vehicle']),
      pickup: TripPlace.fromJson(reader.object('pickup').raw),
      stops: reader.listOf('stops', (item) => TripPlace.fromJson(item.raw)),
      dropoff: TripPlace.fromJson(reader.object('dropoff').raw),
      fare: TripFare.fromJson(reader.object('fare').raw),
      pin: reader.strOrNull('pin'),
      pinExpiresAt: deviceDeadlineOrNull(reader.strOrNull('pinExpiresAt')),
      etaAt: deviceDeadlineOrNull(reader.strOrNull('etaAt')),
      distanceRemainingKm: reader.doubleOrNull('distanceRemainingKm'),
      driverPosition: reader.objectOrNull('driverPosition') == null
          ? null
          : _tryRead(() => DriverPosition.fromJson(reader.object('driverPosition').raw)),
      unreadMessages: reader.intOr('unreadMessages', 0),
      events: reader.listOf('events', (item) => TripEvent.tryParse(item.raw)!),
      cancellationReason: reader.has('cancellationReason')
          ? TripCancelReason.fromCode(reader.strOrNull('cancellationReason'))
          : null,
      cancellationMessage: reader.strOrNull('cancellationMessage'),
      returnFee: reader.intOrNull('returnFee'),
      airport: reader.objectOrNull('airport') == null
          ? null
          : _tryRead(() => TripAirport.fromJson(reader.object('airport').raw)),
      delivery: reader.objectOrNull('delivery') == null
          ? null
          : _tryRead(() => TripDelivery.fromJson(reader.object('delivery').raw)),
    );
  }

  static T? _tryRead<T>(T Function() parse) {
    try {
      return parse();
    } catch (_) {
      return null;
    }
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
  final int? returnFee;
  final TripAirport? airport;
  final TripDelivery? delivery;

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
