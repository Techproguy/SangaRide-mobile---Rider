import 'package:flutter/material.dart';
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride/model/trip/trip.dart';
import 'package:sanga_ride/model/trip/wrapup/payment.dart';
import 'package:sanga_ride/model/trip/wrapup/receipt.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum HistoryEventType {
  driverAccepted('driver_accepted', 'Driver accepted your request', Icons.directions_car_rounded),
  driverArrived('driver_arrived', 'Driver arrived at pick up', Icons.location_on_rounded),
  tripStarted('trip_started', 'Trip started', Icons.directions_car_rounded),
  arrivedDropoff('arrived_dropoff', 'Arrived at destination', Icons.location_on_rounded),
  tripCompleted('trip_completed', 'Ride completed', Icons.check_rounded),
  packagePickedUp('package_picked_up', 'Package picked up', Icons.inventory_2_rounded),
  packageDelivered('package_delivered', 'Package delivered', Icons.check_rounded),
  rideCancelled('ride_cancelled', 'Ride cancelled', Icons.close_rounded),
  deliveryCancelled('delivery_cancelled', 'Delivery cancelled', Icons.close_rounded),
  unknown('unknown', 'Update', Icons.circle_outlined);

  const HistoryEventType(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;

  bool get isCancellation => this == rideCancelled || this == deliveryCancelled;

  static HistoryEventType fromCode(String? code) =>
      enumByCode(values, code, (type) => type.code, HistoryEventType.unknown);

  static HistoryEventType? ofTrip(TripEventType type, {required bool isDelivery}) => switch (type) {
    TripEventType.driverAccepted => driverAccepted,
    TripEventType.driverArrived => driverArrived,
    TripEventType.tripStarted => isDelivery ? packagePickedUp : tripStarted,
    TripEventType.arrivedDropoff => arrivedDropoff,
    TripEventType.tripCompleted => isDelivery ? packageDelivered : tripCompleted,
    TripEventType.tripCancelled => isDelivery ? deliveryCancelled : rideCancelled,
    TripEventType.detailsConfirmed || TripEventType.pinVerified => null,
  };
}

class HistoryEvent {
  const HistoryEvent({required this.type, required this.at});

  static HistoryEvent? tryFromReader(JsonReader reader) {
    final type = HistoryEventType.fromCode(reader.strOrNull('type'));
    if (type == HistoryEventType.unknown) return null;
    return HistoryEvent(type: type, at: reader.time('at').toLocal());
  }

  final HistoryEventType type;
  final DateTime at;
}

enum CancelledBy {
  rider('rider', 'You cancelled'),
  driver('driver', 'Your driver cancelled'),
  system('system', 'Sanga cancelled'),
  unknown('unknown', 'This was cancelled');

  const CancelledBy(this.code, this.label);

  final String code;
  final String label;

  static CancelledBy fromCode(String? code) => enumByCode(values, code, (by) => by.code, CancelledBy.unknown);
}

class HistoryCancellation {
  const HistoryCancellation({required this.by, required this.reason, required this.fee});

  factory HistoryCancellation.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return HistoryCancellation(
      by: CancelledBy.fromCode(reader.strOrNull('by')),
      reason: reader.strOr('reason', ''),
      fee: reader.money('fee'),
    );
  }

  final CancelledBy by;
  final String reason;
  final Money fee;

  bool get hasFee => fee.isPositive;
}

class HistoryDriver {
  const HistoryDriver({required this.profile, required this.isBlocked});

  factory HistoryDriver.fromJson(Map<String, dynamic> json) =>
      HistoryDriver(profile: OfferDriver.fromJson(json), isBlocked: JsonReader(json).boolOr('blocked', false));

  final OfferDriver profile;
  final bool isBlocked;

  HistoryDriver copyWith({bool? isBlocked}) => HistoryDriver(profile: profile, isBlocked: isBlocked ?? this.isBlocked);
}

class HistoryDelivery {
  const HistoryDelivery({
    required this.itemName,
    required this.recipientName,
    required this.recipientPhone,
    this.description,
    this.sizeLabel,
    this.weightLabel,
    this.proofPhotoUrl,
  });

  factory HistoryDelivery.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final item = reader.object('item');
    final recipient = reader.object('recipient');
    return HistoryDelivery(
      itemName: item.str('name'),
      description: item.strOrNull('description'),
      sizeLabel: item.strOrNull('sizeLabel'),
      weightLabel: item.strOrNull('weightLabel'),
      recipientName: recipient.strOr('name', ''),
      recipientPhone: recipient.strOr('phone', ''),
      proofPhotoUrl: reader.objectOrNull('deliveryProof')?.strOrNull('photoUrl'),
    );
  }

  final String itemName;
  final String? description;
  final String? sizeLabel;
  final String? weightLabel;
  final String recipientName;
  final String recipientPhone;
  final String? proofPhotoUrl;

  String? get sizeSummary {
    final parts = [?sizeLabel, ?weightLabel];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class HistoryDetail {
  const HistoryDetail({
    required this.id,
    required this.kind,
    required this.status,
    required this.category,
    required this.reference,
    required this.requestedAt,
    required this.occurredAt,
    required this.route,
    required this.fare,
    required this.lines,
    required this.events,
    this.counterOffer,
    this.distanceKm,
    this.durationMinutes,
    this.paidWith,
    this.driver,
    this.vehicle,
    this.ratedStars,
    this.cancellation,
    this.delivery,
    this.returnFee,
  });

  factory HistoryDetail.fromRide(
    Map<String, dynamic> json, {
    Map<String, dynamic>? receipt,
    Set<String> blockedDriverIds = const {},
  }) {
    final reader = JsonReader.of(json);
    final receiptReader = receipt == null ? null : JsonReader.of(receipt);
    final trip = Trip.fromJson(json);
    final kind = HistoryKind.fromCode(reader.strOrNull('kind'));
    final status = HistoryStatus.fromCode(reader.strOrNull('status'));
    final createdAt = reader.time('createdAt').toLocal();
    final hasDriver = reader.objectOrNull('driver') != null;
    final delivery = reader.objectOrNull('delivery');
    return HistoryDetail(
      id: trip.id,
      kind: kind,
      status: status,
      category: trip.rideType,
      reference: reader.strOr('ref', ''),
      requestedAt: createdAt,
      occurredAt: trip.eventTime(TripEventType.tripCompleted) ?? createdAt,
      route: HistoryRoute.fromRide(reader),
      fare: trip.fare.total,
      distanceKm: reader.doubleOrNull('distanceKm'),
      durationMinutes: reader.intOrNull('durationMin'),
      lines: [
        if (receiptReader != null) ...[
          ...receiptReader.listOf('lines', (line) => ReceiptLine.fromJson(line.raw)),
          ...receiptReader.listOf('adjustments', (line) => ReceiptLine.fromJson(line.raw)),
        ],
      ],
      paidWith: _paymentOf(reader, receiptReader),
      driver: hasDriver
          ? HistoryDriver(profile: trip.driver, isBlocked: blockedDriverIds.contains(trip.driver.id))
          : null,
      vehicle: hasDriver ? trip.vehicle : null,
      events: [
        for (final event in trip.events)
          if (HistoryEventType.ofTrip(event.type, isDelivery: kind.isDelivery) case final type?)
            HistoryEvent(type: type, at: event.at),
      ],
      ratedStars: reader.objectOrNull('rating')?.intOrNull('stars'),
      cancellation: status == HistoryStatus.cancelled
          ? HistoryCancellation(
              by: CancelledBy.fromCode(reader.strOrNull('cancelledBy')),
              reason: (trip.cancellationReason ?? TripCancelReason.other).message,
              fee: reader.moneyOr('cancellationFee', Money.zero()),
            )
          : null,
      delivery: delivery == null ? null : _tryParse(() => HistoryDelivery.fromJson(delivery.raw)),
      returnFee: trip.returnFee,
    );
  }

  static ReceiptPayment? _paymentOf(JsonReader ride, JsonReader? receipt) {
    final payment = receipt?.objectOrNull('payment');
    if (payment != null) return ReceiptPayment.fromJson(payment.raw);
    final method = PaymentMethod.tryFromCode(ride.strOrNull('paymentMethod'));
    return method == null ? null : ReceiptPayment(method: method);
  }

  static T? _tryParse<T>(T Function() parse) {
    try {
      return parse();
    } on Object {
      return null;
    }
  }

  final String id;
  final HistoryKind kind;
  final HistoryStatus status;
  final RideCategory category;
  final String reference;
  final DateTime requestedAt;
  final DateTime occurredAt;
  final HistoryRoute route;
  final Money fare;
  final Money? counterOffer;
  final double? distanceKm;
  final int? durationMinutes;
  final List<ReceiptLine> lines;
  final ReceiptPayment? paidWith;
  final HistoryDriver? driver;
  final DriverVehicle? vehicle;
  final List<HistoryEvent> events;
  final int? ratedStars;
  final HistoryCancellation? cancellation;
  final HistoryDelivery? delivery;
  final Money? returnFee;

  bool get isCompleted => status == HistoryStatus.completed;

  bool get canRebook => kind == HistoryKind.ride;

  bool get hasReceipt => isCompleted && paidWith != null;

  String get title => kind.isDelivery ? 'Delivery details' : 'Ride details';

  String? get distanceLabel {
    final km = distanceKm;
    return km == null ? null : SangaDistance.fromKilometers(km);
  }

  String? get durationLabel {
    final minutes = durationMinutes;
    if (minutes == null) return null;
    return minutes == 1 ? '1 minute' : '$minutes minutes';
  }

  HistoryDetail withDriver(HistoryDriver value) => HistoryDetail(
    id: id,
    kind: kind,
    status: status,
    category: category,
    reference: reference,
    requestedAt: requestedAt,
    occurredAt: occurredAt,
    route: route,
    fare: fare,
    lines: lines,
    events: events,
    counterOffer: counterOffer,
    distanceKm: distanceKm,
    durationMinutes: durationMinutes,
    paidWith: paidWith,
    driver: value,
    vehicle: vehicle,
    ratedStars: ratedStars,
    cancellation: cancellation,
    delivery: delivery,
    returnFee: returnFee,
  );
}

enum HistoryFailure {
  notFound(ServerCode.notFound, 'We can’t find this one', 'It may have been removed. Head back and try again.'),
  connection('connection', 'We couldn’t load the details', CommonCopy.connectionBody),
  unknown('unknown', CommonCopy.serverTroubleTitle, CommonCopy.tryAgainInAMoment);

  const HistoryFailure(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  bool get canRetry => this != notFound;

  static HistoryFailure of(Object error) => switch (ProblemKind.of(error)) {
    ProblemRejected(code: ServerCode.notFound || ServerCode.rideNotFound) => notFound,
    ProblemOffline() => connection,
    _ => unknown,
  };
}

enum HistoryProblem {
  driverNotFound(ServerCode.driverNotFound, 'We can’t find that driver.'),
  unknown('unknown', 'We couldn’t do that. Give it another go.');

  const HistoryProblem(this.code, this.message);

  final String code;
  final String message;

  static HistoryProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemRejected(code: ServerCode.driverNotFound) => driverNotFound,
    _ => unknown,
  };
}

enum HistoryDriverAction { blocking, unblocking }

sealed class HistoryDetailState {
  const HistoryDetailState();
}

final class HistoryDetailLoading extends HistoryDetailState {
  const HistoryDetailLoading();
}

final class HistoryDetailFailed extends HistoryDetailState {
  const HistoryDetailFailed(this.reason);

  final HistoryFailure reason;
}

final class HistoryDetailLoaded extends HistoryDetailState {
  const HistoryDetailLoaded(this.detail, {this.driverAction, this.isStale = false});

  final HistoryDetail detail;
  final bool isStale;
  final HistoryDriverAction? driverAction;
}
