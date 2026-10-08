import 'package:flutter/material.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride/model/trip/wrapup/receipt.dart';

enum HistoryEventType {
  driverAccepted('driver_accepted', 'Driver accepted your request', Icons.directions_car_rounded),
  driverArrived('driver_arrived', 'Driver arrived at pick up', Icons.location_on_rounded),
  tripStarted('trip_started', 'Trip started', Icons.directions_car_rounded),
  arrivedDropoff('arrived_dropoff', 'Arrived at destination', Icons.location_on_rounded),
  tripCompleted('trip_completed', 'Ride completed', Icons.check_rounded),
  packagePickedUp('package_picked_up', 'Package picked up', Icons.inventory_2_rounded),
  packageDelivered('package_delivered', 'Package delivered', Icons.check_rounded),
  rideCancelled('ride_cancelled', 'Ride cancelled', Icons.close_rounded),
  deliveryCancelled('delivery_cancelled', 'Delivery cancelled', Icons.close_rounded);

  const HistoryEventType(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;

  bool get isCancellation => this == rideCancelled || this == deliveryCancelled;

  static HistoryEventType fromCode(String code) => values.firstWhere(
    (type) => type.code == code,
    orElse: () => throw FormatException('Unknown history event: $code'),
  );
}

class HistoryEvent {
  const HistoryEvent({required this.type, required this.at});

  factory HistoryEvent.fromJson(Map<String, dynamic> json) => HistoryEvent(
    type: HistoryEventType.fromCode(json['type'] as String),
    at: DateTime.parse(json['at'] as String).toLocal(),
  );

  final HistoryEventType type;
  final DateTime at;
}

enum CancelledBy {
  rider('rider', 'You cancelled'),
  driver('driver', 'Your driver cancelled'),
  system('system', 'Sanga cancelled');

  const CancelledBy(this.code, this.label);

  final String code;
  final String label;

  static CancelledBy fromCode(String code) =>
      values.firstWhere((by) => by.code == code, orElse: () => throw FormatException('Unknown cancelled by: $code'));
}

class HistoryCancellation {
  const HistoryCancellation({required this.by, required this.reason, required this.fee});

  factory HistoryCancellation.fromJson(Map<String, dynamic> json) => HistoryCancellation(
    by: CancelledBy.fromCode(json['by'] as String),
    reason: json['reason'] as String,
    fee: (json['fee'] as num).toInt(),
  );

  final CancelledBy by;
  final String reason;
  final int fee;

  bool get hasFee => fee > 0;
}

class HistoryDriver {
  const HistoryDriver({required this.profile, required this.isBlocked});

  factory HistoryDriver.fromJson(Map<String, dynamic> json) =>
      HistoryDriver(profile: OfferDriver.fromJson(json), isBlocked: json['blocked'] as bool? ?? false);

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
    this.itemPhotoUrl,
    this.proofPhotoUrl,
  });

  factory HistoryDelivery.fromJson(Map<String, dynamic> json) {
    final item = Map<String, dynamic>.from(json['item'] as Map);
    final recipient = Map<String, dynamic>.from(json['recipient'] as Map);
    final proof = json['deliveryProof'] as Map?;
    return HistoryDelivery(
      itemName: item['name'] as String,
      description: item['description'] as String?,
      sizeLabel: item['sizeLabel'] as String?,
      weightLabel: item['weightLabel'] as String?,
      itemPhotoUrl: item['photoUrl'] as String?,
      recipientName: recipient['name'] as String,
      recipientPhone: recipient['phone'] as String,
      proofPhotoUrl: proof?['photoUrl'] as String?,
    );
  }

  final String itemName;
  final String? description;
  final String? sizeLabel;
  final String? weightLabel;
  final String? itemPhotoUrl;
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
  });

  factory HistoryDetail.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? map(String key) => json[key] is Map ? Map<String, dynamic>.from(json[key] as Map) : null;
    final driver = map('driver');
    final vehicle = map('vehicle');
    final paidWith = map('paidWith');
    final cancellation = map('cancellation');
    final delivery = map('delivery');
    final rating = map('rating');
    return HistoryDetail(
      id: json['id'] as String,
      kind: HistoryKind.fromCode(json['kind'] as String),
      status: HistoryStatus.fromCode(json['status'] as String),
      category: RideCategory.values.asNameMap()[json['category']] ?? RideCategory.go,
      reference: json['reference'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String).toLocal(),
      occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
      route: HistoryRoute.fromJson(json),
      fare: (json['fare'] as num).toInt(),
      counterOffer: (json['counterOffer'] as num?)?.toInt(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      lines: [for (final line in json['lines'] as List) ReceiptLine.fromJson(Map<String, dynamic>.from(line as Map))],
      paidWith: paidWith == null ? null : ReceiptPayment.fromJson(paidWith),
      driver: driver == null ? null : HistoryDriver.fromJson(driver),
      vehicle: vehicle == null ? null : DriverVehicle.fromJson(vehicle),
      events: [
        for (final event in json['events'] as List) HistoryEvent.fromJson(Map<String, dynamic>.from(event as Map)),
      ],
      ratedStars: (rating?['stars'] as num?)?.toInt(),
      cancellation: cancellation == null ? null : HistoryCancellation.fromJson(cancellation),
      delivery: delivery == null ? null : HistoryDelivery.fromJson(delivery),
    );
  }

  final String id;
  final HistoryKind kind;
  final HistoryStatus status;
  final RideCategory category;
  final String reference;
  final DateTime requestedAt;
  final DateTime occurredAt;
  final HistoryRoute route;
  final int fare;
  final int? counterOffer;
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

  bool get isCompleted => status == HistoryStatus.completed;

  bool get canRebook => kind == HistoryKind.ride;

  bool get hasReceipt => isCompleted && paidWith != null;

  String get title => kind.isDelivery ? 'Delivery details' : 'Ride details';

  String? get distanceLabel {
    final km = distanceKm;
    if (km == null) return null;
    final rounded = km.toStringAsFixed(1);
    return '${rounded.endsWith('.0') ? rounded.substring(0, rounded.length - 2) : rounded} km';
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
  );
}

enum HistoryFailure {
  notFound('not_found', 'We can’t find this one', 'It may have been removed. Head back and try again.'),
  connection('connection', 'We couldn’t load the details', 'Check your connection and give it another go.');

  const HistoryFailure(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  bool get canRetry => this != notFound;

  static HistoryFailure fromCode(String? code) =>
      values.firstWhere((failure) => failure.code == code, orElse: () => connection);
}

enum HistoryProblem {
  driverNotFound('driver_not_found', 'We can’t find that driver.'),
  unknown('unknown', 'We couldn’t do that. Give it another go.');

  const HistoryProblem(this.code, this.message);

  final String code;
  final String message;

  static HistoryProblem fromCode(String? code) =>
      values.firstWhere((problem) => problem.code == code, orElse: () => unknown);
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
  const HistoryDetailLoaded(this.detail, {this.driverAction});

  final HistoryDetail detail;
  final HistoryDriverAction? driverAction;
}
