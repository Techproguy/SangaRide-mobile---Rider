import 'package:sanga_ride/model/delivery/delivery_catalog.dart';
import 'package:sanga_ride/model/ride/ride_for.dart';

class BookingRecipient {
  const BookingRecipient({required this.name, required this.phone, this.email, this.gender});

  final String name;
  final String phone;
  final String? email;
  final PassengerGender? gender;

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'email': email, 'gender': gender?.code};
}

class BookingItem {
  const BookingItem({
    required this.name,
    required this.description,
    required this.sizeId,
    required this.packageTypeId,
    required this.photoId,
    required this.declaredValue,
  });

  final String name;
  final String description;
  final String sizeId;
  final String packageTypeId;
  final String? photoId;
  final int? declaredValue;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'size': sizeId,
    'packageType': packageTypeId,
    'photoId': photoId,
    'declaredValue': declaredValue,
  };
}

class DeliveryBooking {
  const DeliveryBooking({
    required this.quoteId,
    required this.tierId,
    required this.kindId,
    required this.fare,
    required this.item,
    required this.recipient,
  });

  final String quoteId;
  final String tierId;
  final String kindId;
  final int fare;
  final BookingItem item;
  final BookingRecipient recipient;

  Map<String, dynamic> toJson() => {
    'quoteId': quoteId,
    'tier': tierId,
    'kind': kindId,
    'item': item.toJson(),
    'recipient': recipient.toJson(),
  };
}

class DeliveryDraft {
  const DeliveryDraft({
    this.kindId,
    this.name = '',
    this.description = '',
    this.sizeId,
    this.packageTypeId,
    this.declaredValue,
    this.tierId,
    this.recipient,
  });

  final String? kindId;
  final String name;
  final String description;
  final String? sizeId;
  final String? packageTypeId;
  final int? declaredValue;
  final String? tierId;
  final BookingRecipient? recipient;

  DeliveryDraft copyWith({
    String? kindId,
    String? name,
    String? description,
    String? sizeId,
    String? packageTypeId,
    int? Function()? declaredValue,
    String? tierId,
    BookingRecipient? recipient,
  }) => DeliveryDraft(
    kindId: kindId ?? this.kindId,
    name: name ?? this.name,
    description: description ?? this.description,
    sizeId: sizeId ?? this.sizeId,
    packageTypeId: packageTypeId ?? this.packageTypeId,
    declaredValue: declaredValue == null ? this.declaredValue : declaredValue(),
    tierId: tierId ?? this.tierId,
    recipient: recipient ?? this.recipient,
  );

  bool isItemComplete(DeliveryCatalog catalog) {
    if (kindId == null || name.trim().isEmpty || description.trim().isEmpty) return false;
    if (catalog.kindOf(kindId)?.isDocuments ?? false) return true;
    return catalog.sizeOf(sizeId) != null && catalog.packageTypeOf(packageTypeId) != null;
  }

  String? effectiveSizeId(DeliveryCatalog catalog) {
    if (catalog.kindOf(kindId)?.isDocuments ?? false) return catalog.smallestSize?.id;
    return sizeId;
  }

  String? effectivePackageTypeId(DeliveryCatalog catalog) {
    if (catalog.kindOf(kindId)?.isDocuments ?? false) return catalog.defaultPackageType?.id;
    return packageTypeId;
  }
}
