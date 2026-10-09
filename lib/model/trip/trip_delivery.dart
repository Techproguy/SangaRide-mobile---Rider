import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';

enum DeliveryStage {
  toPickup('to_pickup'),
  atPickup('at_pickup'),
  inspecting('inspecting'),
  pickedUp('picked_up'),
  toDropoff('to_dropoff'),
  atDropoff('at_dropoff'),
  verifyingRecipient('verifying_recipient'),
  delivered('delivered'),
  refused('refused'),
  returning('returning'),
  returned('returned');

  const DeliveryStage(this.code);

  final String code;

  bool get canCancel => this == toPickup || this == atPickup;

  bool get isPastPickup => index >= pickedUp.index && this != refused;

  bool get isReturn => this == returning || this == returned;

  bool get isEnded => this == delivered || this == refused || this == returned;

  static DeliveryStage fromCode(String code) => values.firstWhere(
    (stage) => stage.code == code,
    orElse: () => throw FormatException('Unknown delivery stage: $code'),
  );
}

enum DeliveryEventType {
  accepted('accepted', 'Driver accepted your request'),
  arrivedPickup('arrived_pickup', 'Driver arrived at pick up'),
  pickedUp('picked_up', 'Package picked up'),
  arrivedDropoff('arrived_dropoff', 'Arrived at drop off'),
  handedOver('handed_over', 'Handed over to recipient'),
  delivered('delivered', 'Delivery completed'),
  returnStarted('return_started', 'Heading back to pickup'),
  returned('returned', 'Package back at pickup');

  const DeliveryEventType(this.code, this.label);

  static const List<DeliveryEventType> outbound = [
    accepted,
    arrivedPickup,
    pickedUp,
    arrivedDropoff,
    handedOver,
    delivered,
  ];

  static const List<DeliveryEventType> returnLeg = [
    accepted,
    arrivedPickup,
    pickedUp,
    arrivedDropoff,
    returnStarted,
    returned,
  ];

  final String code;
  final String label;

  static DeliveryEventType? fromCode(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

class DeliveryEvent {
  const DeliveryEvent({required this.type, required this.at});

  static DeliveryEvent? tryParse(Map<String, dynamic> json) {
    final type = DeliveryEventType.fromCode(json['type'] as String?);
    if (type == null) return null;
    final at = json['at'] as String?;
    return DeliveryEvent(type: type, at: at == null ? null : DateTime.parse(at).toLocal());
  }

  final DeliveryEventType type;
  final DateTime? at;
}

enum DeliveryKind {
  documents('documents', 'Documents'),
  package('package', 'Package');

  const DeliveryKind(this.code, this.label);

  final String code;
  final String label;

  static DeliveryKind fromCode(String? code) => values.firstWhere((kind) => kind.code == code, orElse: () => package);
}

enum DeliveryPackageType {
  fragile('fragile', 'Fragile'),
  notFragile('not_fragile', 'Not fragile'),
  perishable('perishable', 'Perishable');

  const DeliveryPackageType(this.code, this.label);

  final String code;
  final String label;

  static DeliveryPackageType? fromCode(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

abstract final class DeliveryTier {
  static const Map<String, String> _labels = {
    'standard': 'Standard',
    'express': 'Express',
    'priority': 'Priority',
    'premium_care': 'Premium Care',
  };

  static String labelOf(String code) {
    final known = _labels[code];
    if (known != null) return known;
    final words = code.split('_').where((word) => word.isNotEmpty);
    return words.map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}

class DeliveryItem {
  const DeliveryItem({
    required this.name,
    required this.description,
    required this.sizeLabel,
    required this.weightLabel,
    required this.packageType,
    required this.photoUrl,
    required this.declaredValue,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) => DeliveryItem(
    name: json['name'] as String,
    description: json['description'] as String?,
    sizeLabel: json['sizeLabel'] as String? ?? '',
    weightLabel: json['weightLabel'] as String?,
    packageType: DeliveryPackageType.fromCode(json['packageType'] as String?),
    photoUrl: json['photoUrl'] as String?,
    declaredValue: (json['declaredValue'] as num?)?.toInt(),
  );

  final String name;
  final String? description;
  final String sizeLabel;
  final String? weightLabel;
  final DeliveryPackageType? packageType;
  final String? photoUrl;
  final int? declaredValue;

  String get summary => [if (sizeLabel.isNotEmpty) sizeLabel, ?weightLabel, ?packageType?.label].join(' · ');
}

class DeliveryRecipient {
  const DeliveryRecipient({required this.name, required this.phone});

  factory DeliveryRecipient.fromJson(Map<String, dynamic> json) =>
      DeliveryRecipient(name: json['name'] as String, phone: json['phone'] as String? ?? '');

  final String name;
  final String phone;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}

class PickupProof {
  const PickupProof({required this.photoUrl, required this.at});

  factory PickupProof.fromJson(Map<String, dynamic> json) =>
      PickupProof(photoUrl: json['photoUrl'] as String?, at: DateTime.parse(json['at'] as String).toLocal());

  final String? photoUrl;
  final DateTime at;
}

class SenderConfirmation {
  const SenderConfirmation({required this.photoUrl, required this.at});

  factory SenderConfirmation.fromJson(Map<String, dynamic> json) =>
      SenderConfirmation(photoUrl: json['photoUrl'] as String?, at: DateTime.parse(json['at'] as String).toLocal());

  final String? photoUrl;
  final DateTime at;
}

class DeliveryProof {
  const DeliveryProof({
    required this.photoUrl,
    required this.at,
    required this.position,
    required this.recipientConfirmed,
  });

  factory DeliveryProof.fromJson(Map<String, dynamic> json) => DeliveryProof(
    photoUrl: json['photoUrl'] as String?,
    at: DateTime.parse(json['at'] as String).toLocal(),
    position: LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble()),
    recipientConfirmed: json['recipientConfirmed'] as bool? ?? false,
  );

  static const double verifiedRadiusMeters = 150;

  final String? photoUrl;
  final DateTime at;
  final LatLng position;
  final bool recipientConfirmed;

  bool isAtDropoff(LatLng dropoff) => position.metersTo(dropoff) <= verifiedRadiusMeters;
}

enum DeliveryRefusalReason {
  prohibited(
    'prohibited',
    'This item isn’t allowed',
    'Your driver can’t carry items that are restricted or hazardous.',
  ),
  notAsDeclared(
    'not_as_declared',
    'The package didn’t match',
    'What your driver found didn’t match the item you described.',
  ),
  suspicious('suspicious', 'Your driver couldn’t take it', 'They couldn’t verify what was inside the package.'),
  damaged('damaged', 'The package looked damaged', 'It wasn’t safe to carry the package in this condition.'),
  other('other', 'Your driver couldn’t take it', 'They weren’t able to carry the package this time.');

  const DeliveryRefusalReason(this.code, this.title, this.detail);

  final String code;
  final String title;
  final String detail;

  static DeliveryRefusalReason fromCode(String? code) =>
      values.firstWhere((reason) => reason.code == code, orElse: () => other);
}

class DeliveryRefusal {
  const DeliveryRefusal({required this.reason, required this.note, required this.message, required this.at});

  factory DeliveryRefusal.fromJson(Map<String, dynamic> json) => DeliveryRefusal(
    reason: DeliveryRefusalReason.fromCode(json['reason'] as String?),
    note: json['note'] as String?,
    message: json['message'] as String?,
    at: DateTime.parse(json['at'] as String).toLocal(),
  );

  final DeliveryRefusalReason reason;
  final String? note;
  final String? message;
  final DateTime at;
}

class TripDelivery {
  const TripDelivery({
    required this.tier,
    required this.kind,
    required this.item,
    required this.recipient,
    required this.stage,
    required this.pickupProof,
    required this.senderConfirmation,
    required this.deliveryProof,
    required this.refusal,
    required this.events,
  });

  factory TripDelivery.fromJson(Map<String, dynamic> json) {
    final pickupProof = json['pickupProof'] as Map?;
    final senderConfirmation = json['senderConfirmation'] as Map?;
    final deliveryProof = json['deliveryProof'] as Map?;
    final refusal = json['refusal'] as Map?;
    return TripDelivery(
      tier: json['tier'] as String,
      kind: DeliveryKind.fromCode(json['kind'] as String?),
      item: DeliveryItem.fromJson(Map<String, dynamic>.from(json['item'] as Map)),
      recipient: DeliveryRecipient.fromJson(Map<String, dynamic>.from(json['recipient'] as Map)),
      stage: DeliveryStage.fromCode(json['stage'] as String),
      pickupProof: pickupProof == null ? null : PickupProof.fromJson(Map<String, dynamic>.from(pickupProof)),
      senderConfirmation: senderConfirmation == null
          ? null
          : SenderConfirmation.fromJson(Map<String, dynamic>.from(senderConfirmation)),
      deliveryProof: deliveryProof == null ? null : DeliveryProof.fromJson(Map<String, dynamic>.from(deliveryProof)),
      refusal: refusal == null ? null : DeliveryRefusal.fromJson(Map<String, dynamic>.from(refusal)),
      events: [
        for (final event in json['events'] as List? ?? const [])
          ?DeliveryEvent.tryParse(Map<String, dynamic>.from(event as Map)),
      ],
    );
  }

  final String tier;
  final DeliveryKind kind;
  final DeliveryItem item;
  final DeliveryRecipient recipient;
  final DeliveryStage stage;
  final PickupProof? pickupProof;
  final SenderConfirmation? senderConfirmation;
  final DeliveryProof? deliveryProof;
  final DeliveryRefusal? refusal;
  final List<DeliveryEvent> events;

  String get tierLabel => DeliveryTier.labelOf(tier);

  bool hasEvent(DeliveryEventType type) => events.any((event) => event.type == type && event.at != null);

  DateTime? eventTime(DeliveryEventType type) {
    for (final event in events) {
      if (event.type == type) return event.at;
    }
    return null;
  }
}

enum DeliveryPhaseTone { neutral, primary, success }

enum DeliveryPhase {
  heading('Your driver is heading to pickup', DeliveryPhaseTone.neutral),
  atPickup('Your driver is at the pickup', DeliveryPhaseTone.success),
  sharingPin('Share your PIN to hand over the package', DeliveryPhaseTone.primary),
  confirmPickup('Confirm the package with your driver', DeliveryPhaseTone.primary),
  checking('Your driver is checking the package', DeliveryPhaseTone.neutral),
  payment('Package picked up', DeliveryPhaseTone.success),
  onTheWay('On the way to the drop off', DeliveryPhaseTone.neutral),
  atDropoff('Your driver is at the drop off', DeliveryPhaseTone.success),
  verifying('Your driver is meeting the recipient', DeliveryPhaseTone.neutral),
  handedOver('Package handed over to recipient', DeliveryPhaseTone.success),
  returning('Your package is heading back to the pickup', DeliveryPhaseTone.neutral);

  const DeliveryPhase(this.statusLine, this.tone);

  final String statusLine;
  final DeliveryPhaseTone tone;

  bool get showsEta => this == heading || this == onTheWay || this == returning;

  bool get canReport => this != atPickup && this != sharingPin && this != returning;

  int get progressStage => switch (this) {
    atDropoff || verifying => 1,
    handedOver => 2,
    _ => 0,
  };

  static DeliveryPhase afterPin(TripDelivery delivery) {
    if (delivery.stage.isPastPickup) return payment;
    return delivery.senderConfirmation == null ? confirmPickup : checking;
  }

  static DeliveryPhase atDropoffOf(DeliveryStage stage) => switch (stage) {
    DeliveryStage.verifyingRecipient => verifying,
    DeliveryStage.delivered => handedOver,
    _ => atDropoff,
  };
}
