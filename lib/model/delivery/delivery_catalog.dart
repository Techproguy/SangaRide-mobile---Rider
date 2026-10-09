import 'package:sanga_ride_core/sanga_ride_core.dart';

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

  factory DeliveryKindOption.fromReader(JsonReader reader) =>
      DeliveryKindOption(id: reader.str('id'), label: reader.str('label'), hint: reader.str('hint'));

  final String id;
  final String label;
  final String hint;

  bool get isDocuments => id == DeliveryRules.documentsKindId;
}

class PackageSize {
  const PackageSize({required this.id, required this.label, required this.maxKg});

  factory PackageSize.fromReader(JsonReader reader) =>
      PackageSize(id: reader.str('id'), label: reader.str('label'), maxKg: reader.number('maxKg').toInt());

  final String id;
  final String label;
  final int maxKg;

  String get weightLabel => 'up to ${maxKg}kg';

  String get chipLabel => '$label · $weightLabel';
}

class PackageType {
  const PackageType({required this.id, required this.label});

  factory PackageType.fromReader(JsonReader reader) => PackageType(id: reader.str('id'), label: reader.str('label'));

  final String id;
  final String label;
}

class DeliveryTierInfo {
  const DeliveryTierInfo({required this.id, required this.label, required this.blurb, required this.etaMinutes});

  factory DeliveryTierInfo.fromReader(JsonReader reader) => DeliveryTierInfo(
    id: reader.str('id'),
    label: reader.str('label'),
    blurb: reader.str('blurb'),
    etaMinutes: [for (final minutes in _requiredList(reader, 'etaMinutes')) (minutes as num).toInt()],
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

  factory DeliveryCatalog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return DeliveryCatalog(
      kinds: _parseAll(reader, 'kinds', DeliveryKindOption.fromReader),
      sizes: _parseAll(reader, 'sizes', PackageSize.fromReader),
      packageTypes: _parseAll(reader, 'packageTypes', PackageType.fromReader),
      tiers: _parseAll(reader, 'tiers', DeliveryTierInfo.fromReader),
      highValueThreshold: reader.number('highValueThreshold').toInt(),
      maxDeclaredValue: reader.number('maxDeclaredValue').toInt(),
      prohibitedNotice: reader.str('prohibitedNotice'),
    );
  }

  static List<T> _parseAll<T>(JsonReader reader, String key, T Function(JsonReader item) parse) => [
    for (final item in _requiredList(reader, key)) parse(JsonReader.of(item)),
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

List<Object?> _requiredList(JsonReader reader, String key) {
  final value = reader.raw[key];
  if (value is! List) throw JsonFormatError('Expected a list at "$key"', value);
  return value;
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
