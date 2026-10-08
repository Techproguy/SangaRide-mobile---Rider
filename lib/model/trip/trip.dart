import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/ride/airport.dart';
import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride/model/trip/server_time.dart';
import 'package:sanga_ride/model/trip/trip_delivery.dart';

enum TripStatus {
  driverEnRoute('driver_en_route'),
  driverArrived('driver_arrived'),
  pinVerified('pin_verified'),
  inProgress('in_progress'),
  arrivedDropoff('arrived_dropoff'),
  paymentPending('payment_pending'),
  completed('completed'),
  cancelled('cancelled');

  const TripStatus(this.code);

  final String code;

  int get rank => index;

  bool get isTerminal => this == completed || this == cancelled;

  bool get canChange => this == driverEnRoute || this == driverArrived || this == inProgress;

  static TripStatus fromCode(String code) => values.firstWhere(
    (status) => status.code == code,
    orElse: () => throw FormatException('Unknown trip status: $code'),
  );

  static TripStatus advance(TripStatus current, TripStatus incoming) {
    if (current.isTerminal) return current;
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
    final type = TripEventType.fromCode(json['type'] as String?);
    if (type == null) return null;
    return TripEvent(type: type, at: DateTime.parse(json['at'] as String).toLocal());
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
    'Package heading back',
    'Your driver couldn’t hand the package over, so it’s going back to the pickup location.',
  ),
  other('other', 'Trip cancelled', 'This trip was cancelled. You won’t be charged.');

  const TripCancelReason(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  bool get offersRematch => this == driverCancelled;

  static TripCancelReason fromCode(String? code) =>
      values.firstWhere((reason) => reason.code == code, orElse: () => other);
}

enum TripLoadFailure {
  notFound('We can’t find this trip', 'It may have ended. Head back home to see what’s next.', canRetry: false),
  connection('We couldn’t load your trip', 'Check your connection and give it another go.', canRetry: true);

  const TripLoadFailure(this.title, this.message, {required this.canRetry});

  final String title;
  final String message;
  final bool canRetry;
}

LatLng _latLng(Map<String, dynamic> json) => LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());

class TripPlace {
  const TripPlace({required this.name, required this.address, required this.position, this.isReached = false});

  factory TripPlace.fromJson(Map<String, dynamic> json) => TripPlace(
    name: json['name'] as String,
    address: json['address'] as String? ?? '',
    position: _latLng(Map<String, dynamic>.from(json['coordinates'] as Map)),
    isReached: json['status'] == 'reached',
  );

  final String name;
  final String address;
  final LatLng position;
  final bool isReached;

  Place toPlace() => Place(placeId: '', name: name, address: address, coordinates: position);
}

class TripFare {
  const TripFare({required this.total, required this.counterOffer});

  factory TripFare.fromJson(Map<String, dynamic> json) =>
      TripFare(total: (json['total'] as num).toInt(), counterOffer: (json['counterOffer'] as num?)?.toInt());

  final int total;
  final int? counterOffer;
}

class DriverPosition {
  const DriverPosition({required this.position, required this.heading});

  factory DriverPosition.fromJson(Map<String, dynamic> json) =>
      DriverPosition(position: _latLng(json), heading: (json['heading'] as num?)?.toDouble());

  final LatLng position;
  final double? heading;
}

DateTime? _deadline(Map<String, dynamic> json, String key, DateTime serverTime) {
  final value = json[key] as String?;
  return value == null ? null : deadlineAfter(serverTime, value);
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
    this.airport,
    this.delivery,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final serverTime = DateTime.parse(json['serverTime'] as String);
    final position = json['driverPosition'] as Map?;
    final airport = json['airport'] as Map?;
    final delivery = json['delivery'] as Map?;
    return Trip(
      id: json['id'] as String,
      status: TripStatus.fromCode(json['status'] as String),
      rideType: RideCategory.values.asNameMap()[json['rideType']] ?? RideCategory.go,
      driver: OfferDriver.fromJson(Map<String, dynamic>.from(json['driver'] as Map)),
      vehicle: DriverVehicle.fromJson(Map<String, dynamic>.from(json['vehicle'] as Map)),
      pickup: TripPlace.fromJson(Map<String, dynamic>.from(json['pickup'] as Map)),
      stops: [for (final stop in json['stops'] as List) TripPlace.fromJson(Map<String, dynamic>.from(stop as Map))],
      dropoff: TripPlace.fromJson(Map<String, dynamic>.from(json['dropoff'] as Map)),
      fare: TripFare.fromJson(Map<String, dynamic>.from(json['fare'] as Map)),
      pin: json['pin'] as String?,
      pinExpiresAt: _deadline(json, 'pinExpiresAt', serverTime),
      etaAt: _deadline(json, 'etaAt', serverTime),
      distanceRemainingKm: (json['distanceRemainingKm'] as num?)?.toDouble(),
      driverPosition: position == null ? null : DriverPosition.fromJson(Map<String, dynamic>.from(position)),
      unreadMessages: (json['unreadMessages'] as num?)?.toInt() ?? 0,
      events: [
        for (final event in json['events'] as List? ?? const [])
          ?TripEvent.tryParse(Map<String, dynamic>.from(event as Map)),
      ],
      cancellationReason: json['cancellationReason'] == null
          ? null
          : TripCancelReason.fromCode(json['cancellationReason'] as String),
      airport: airport == null ? null : TripAirport.fromJson(Map<String, dynamic>.from(airport)),
      delivery: delivery == null ? null : TripDelivery.fromJson(Map<String, dynamic>.from(delivery)),
    );
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
  final TripAirport? airport;
  final TripDelivery? delivery;

  static const int maxStops = 3;

  List<TripPlace> get route => [pickup, ...stops, dropoff];

  bool get isDelivery => delivery != null;

  bool get canChange => status.canChange && (delivery?.stage.canCancel ?? true);

  bool get canAddStops => !isDelivery && canChange && stops.length < maxStops;

  DeliveryPhase? get deliveryPhase {
    final delivery = this.delivery;
    if (delivery == null || delivery.stage == DeliveryStage.refused || delivery.stage == DeliveryStage.failed) {
      return null;
    }
    return switch (status) {
      TripStatus.driverEnRoute => DeliveryPhase.heading,
      TripStatus.driverArrived => pin == null ? DeliveryPhase.atPickup : DeliveryPhase.sharingPin,
      TripStatus.pinVerified => DeliveryPhase.afterPin(delivery),
      TripStatus.inProgress => DeliveryPhase.onTheWay,
      TripStatus.arrivedDropoff || TripStatus.paymentPending => DeliveryPhase.atDropoffOf(delivery.stage),
      TripStatus.completed || TripStatus.cancelled => null,
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
