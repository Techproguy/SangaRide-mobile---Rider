abstract final class DeliveryRules {
  static const String documentsKindId = 'documents';
  static const String defaultPackageTypeId = 'not_fragile';
  static const String premiumTierId = 'premium_care';
  static const int itemNameMaxLength = 60;
  static const int descriptionMaxLength = 200;
  static const int recipientNameMaxLength = 60;
  static const int maxPhotoBytes = 8 * 1024 * 1024;
}

String deliveryEtaLabel(List<int> minutes) {
  if (minutes.isEmpty) return '';
  if (minutes.length == 1 || minutes.first == minutes.last) return '${minutes.first} mins';
  return '${minutes.first} to ${minutes.last} mins';
}

class DeliveryKindOption {
  const DeliveryKindOption({required this.id, required this.label, required this.hint});

  factory DeliveryKindOption.fromJson(Map<String, dynamic> json) =>
      DeliveryKindOption(id: json['id'] as String, label: json['label'] as String, hint: json['hint'] as String);

  final String id;
  final String label;
  final String hint;

  bool get isDocuments => id == DeliveryRules.documentsKindId;
}

class PackageSize {
  const PackageSize({required this.id, required this.label, required this.maxKg});

  factory PackageSize.fromJson(Map<String, dynamic> json) =>
      PackageSize(id: json['id'] as String, label: json['label'] as String, maxKg: (json['maxKg'] as num).toInt());

  final String id;
  final String label;
  final int maxKg;

  String get weightLabel => 'up to ${maxKg}kg';

  String get chipLabel => '$label · $weightLabel';
}

class PackageType {
  const PackageType({required this.id, required this.label});

  factory PackageType.fromJson(Map<String, dynamic> json) =>
      PackageType(id: json['id'] as String, label: json['label'] as String);

  final String id;
  final String label;
}

class DeliveryTierInfo {
  const DeliveryTierInfo({required this.id, required this.label, required this.blurb, required this.etaMinutes});

  factory DeliveryTierInfo.fromJson(Map<String, dynamic> json) => DeliveryTierInfo(
    id: json['id'] as String,
    label: json['label'] as String,
    blurb: json['blurb'] as String,
    etaMinutes: [for (final minutes in json['etaMinutes'] as List) (minutes as num).toInt()],
  );

  final String id;
  final String label;
  final String blurb;
  final List<int> etaMinutes;
}

class DeliveryCatalog {
  const DeliveryCatalog({
    required this.kinds,
    required this.sizes,
    required this.packageTypes,
    required this.tiers,
    required this.highValueThreshold,
    required this.maxDeclaredValue,
    required this.prohibitedNotice,
  });

  factory DeliveryCatalog.fromJson(Map<String, dynamic> json) => DeliveryCatalog(
    kinds: _list(json['kinds'], DeliveryKindOption.fromJson),
    sizes: _list(json['sizes'], PackageSize.fromJson),
    packageTypes: _list(json['packageTypes'], PackageType.fromJson),
    tiers: _list(json['tiers'], DeliveryTierInfo.fromJson),
    highValueThreshold: (json['highValueThreshold'] as num).toInt(),
    maxDeclaredValue: (json['maxDeclaredValue'] as num).toInt(),
    prohibitedNotice: json['prohibitedNotice'] as String,
  );

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) => [
    for (final json in raw as List) parse(Map<String, dynamic>.from(json as Map)),
  ];

  final List<DeliveryKindOption> kinds;
  final List<PackageSize> sizes;
  final List<PackageType> packageTypes;
  final List<DeliveryTierInfo> tiers;
  final int highValueThreshold;
  final int maxDeclaredValue;
  final String prohibitedNotice;

  DeliveryKindOption? kindOf(String? id) => kinds.where((kind) => kind.id == id).firstOrNull;

  PackageSize? sizeOf(String? id) => sizes.where((size) => size.id == id).firstOrNull;

  PackageType? packageTypeOf(String? id) => packageTypes.where((type) => type.id == id).firstOrNull;

  DeliveryTierInfo? tierOf(String? id) => tiers.where((tier) => tier.id == id).firstOrNull;

  PackageSize? get smallestSize => sizes.isEmpty ? null : sizes.reduce((a, b) => a.maxKg <= b.maxKg ? a : b);

  PackageType? get defaultPackageType => packageTypeOf(DeliveryRules.defaultPackageTypeId) ?? packageTypes.firstOrNull;

  String get premiumTierLabel => tierOf(DeliveryRules.premiumTierId)?.label ?? 'a premium tier';

  bool isHighValue(int? value) => value != null && value >= highValueThreshold;
}

sealed class DeliveryCatalogState {
  const DeliveryCatalogState();
}

final class DeliveryCatalogLoading extends DeliveryCatalogState {
  const DeliveryCatalogLoading();
}

final class DeliveryCatalogFailed extends DeliveryCatalogState {
  const DeliveryCatalogFailed();
}

final class DeliveryCatalogReady extends DeliveryCatalogState {
  const DeliveryCatalogReady(this.catalog);

  final DeliveryCatalog catalog;
}
