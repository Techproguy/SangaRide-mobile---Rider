import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

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
  returned('returned'),
  unknown('unknown');

  const DeliveryStage(this.code);

  final String code;

  bool get canCancel => this == toPickup || this == atPickup;

  bool get isPastPickup => this != unknown && index >= pickedUp.index && this != refused;

  bool get isReturn => this == returning || this == returned;

  bool get isEnded => this == delivered || this == refused || this == returned;

  static DeliveryStage fromCode(String? code) => enumByCode(values, code, (stage) => stage.code, unknown);
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
    final reader = JsonReader.of(json);
    final type = DeliveryEventType.fromCode(reader.strOrNull('type'));
    if (type == null) return null;
    return DeliveryEvent(type: type, at: reader.timeOrNull('at')?.toLocal());
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

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return DeliveryItem(
      name: reader.str('name'),
      description: reader.strOrNull('description'),
      sizeLabel: reader.strOr('sizeLabel', ''),
      weightLabel: reader.strOrNull('weightLabel'),
      packageType: DeliveryPackageType.fromCode(reader.strOrNull('packageType')),
      photoUrl: reader.strOrNull('photoUrl'),
      declaredValue: reader.intOrNull('declaredValue'),
    );
  }

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

  factory DeliveryRecipient.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return DeliveryRecipient(name: reader.str('name'), phone: reader.strOr('phone', ''));
  }

  final String name;
  final String phone;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}

class PickupProof {
  const PickupProof({required this.photoUrl, required this.at});

  factory PickupProof.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return PickupProof(photoUrl: reader.strOrNull('photoUrl'), at: reader.time('at').toLocal());
  }

  final String? photoUrl;
  final DateTime at;
}

class SenderConfirmation {
  const SenderConfirmation({required this.photoUrl, required this.at});

  factory SenderConfirmation.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return SenderConfirmation(photoUrl: reader.strOrNull('photoUrl'), at: reader.time('at').toLocal());
  }

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

  factory DeliveryProof.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return DeliveryProof(
      photoUrl: reader.strOrNull('photoUrl'),
      at: reader.time('at').toLocal(),
      position: LatLng(reader.number('lat').toDouble(), reader.number('lng').toDouble()),
      recipientConfirmed: reader.boolOr('recipientConfirmed', false),
    );
  }

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

  factory DeliveryRefusal.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return DeliveryRefusal(
      reason: DeliveryRefusalReason.fromCode(reader.strOrNull('reason')),
      note: reader.strOrNull('note'),
      message: reader.strOrNull('message'),
      at: reader.timeOrNull('at')?.toLocal() ?? DateTime.now(),
    );
  }

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
    this.openIssueId,
  });

  factory TripDelivery.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return TripDelivery(
      tier: reader.strOr('tier', 'standard'),
      kind: DeliveryKind.fromCode(reader.strOrNull('kind')),
      item: DeliveryItem.fromJson(reader.object('item').raw),
      recipient: DeliveryRecipient.fromJson(reader.object('recipient').raw),
      stage: DeliveryStage.fromCode(reader.strOrNull('stage')),
      pickupProof: _optional(reader, 'pickupProof', PickupProof.fromJson),
      senderConfirmation: _optional(reader, 'senderConfirmation', SenderConfirmation.fromJson),
      deliveryProof: _optional(reader, 'deliveryProof', DeliveryProof.fromJson),
      refusal: _optional(reader, 'refusal', DeliveryRefusal.fromJson),
      events: reader.listOf('events', (item) => DeliveryEvent.tryParse(item.raw)!),
      openIssueId: reader.strOrNull('openIssueId'),
    );
  }

  static T? _optional<T>(JsonReader reader, String key, T Function(Map<String, dynamic> json) parse) {
    final object = reader.objectOrNull(key);
    if (object == null) return null;
    try {
      return parse(object.raw);
    } catch (_) {
      return null;
    }
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
  final String? openIssueId;

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
