import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class DeliveryRules {
  static const Set<String> documentsKindIds = {'document', 'documents'};
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

  factory DeliveryKindOption.fromReader(JsonReader reader) => DeliveryKindOption(
    id: _codeOf(reader),
    label: reader.str('label'),
    hint: reader.strOrNull('hint') ?? reader.strOr('subtitle', ''),
  );

  final String id;
  final String label;
  final String hint;

  bool get isDocuments => DeliveryRules.documentsKindIds.contains(id);
}

class PackageSize {
  const PackageSize({required this.id, required this.label, required this.weightLabel});

  factory PackageSize.fromReader(JsonReader reader) {
    final maxKg = reader.raw['maxKg'];
    return PackageSize(
      id: _codeOf(reader),
      label: reader.str('label'),
      weightLabel: maxKg is num ? 'up to ${maxKg.toInt()}kg' : reader.strOr('subtitle', ''),
    );
  }

  final String id;
  final String label;
  final String weightLabel;

  String get chipLabel => weightLabel.isEmpty ? label : '$label · $weightLabel';
}

class PackageType {
  const PackageType({required this.id, required this.label});

  factory PackageType.fromReader(JsonReader reader) => PackageType(id: _codeOf(reader), label: reader.str('label'));

  final String id;
  final String label;
}

class DeliveryTierInfo {
  const DeliveryTierInfo({
    required this.id,
    required this.label,
    required this.blurb,
    required this.etaMinutes,
    this.basePrice,
  });

  factory DeliveryTierInfo.fromReader(JsonReader reader) {
    final etas = reader.raw['etaMinutes'];
    return DeliveryTierInfo(
      id: _codeOf(reader),
      label: reader.str('label'),
      blurb: reader.strOrNull('blurb') ?? reader.strOr('subtitle', ''),
      etaMinutes: etas is List
          ? [for (final minutes in etas) (minutes as num).toInt()]
          : [?reader.intOrNull('etaMinMinutes'), ?reader.intOrNull('etaMaxMinutes')],
      basePrice: Money.tryParse(reader.raw['price']),
    );
  }

  final String id;
  final String label;
  final String blurb;
  final List<int> etaMinutes;
  final Money? basePrice;
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
      kinds: reader.raw.containsKey('kinds')
          ? _parseAll(reader, 'kinds', DeliveryKindOption.fromReader)
          : _parseAll(reader, 'packageTypes', DeliveryKindOption.fromReader),
      sizes: _parseAll(reader, 'sizes', PackageSize.fromReader),
      packageTypes: reader.raw.containsKey('kinds')
          ? _parseAll(reader, 'packageTypes', PackageType.fromReader)
          : const [],
      tiers: _parseAll(reader, 'tiers', DeliveryTierInfo.fromReader),
      highValueThreshold: _requiredMoney(reader, 'highValueThreshold'),
      maxDeclaredValue: Money.tryParse(reader.raw['maxDeclaredValue']),
      prohibitedNotice: reader.strOrNull('prohibitedNotice') ?? reader.str('prohibitedNote'),
    );
  }

  static List<T> _parseAll<T>(JsonReader reader, String key, T Function(JsonReader item) parse) => [
    for (final item in _requiredList(reader, key)) parse(JsonReader.of(item)),
  ];

  final List<DeliveryKindOption> kinds;
  final List<PackageSize> sizes;
  final List<PackageType> packageTypes;
  final List<DeliveryTierInfo> tiers;
  final Money highValueThreshold;
  final Money? maxDeclaredValue;
  final String prohibitedNotice;

  DeliveryKindOption? kindOf(String? id) => kinds.where((kind) => kind.id == id).firstOrNull;

  PackageSize? sizeOf(String? id) => sizes.where((size) => size.id == id).firstOrNull;

  PackageType? packageTypeOf(String? id) => packageTypes.where((type) => type.id == id).firstOrNull;

  DeliveryTierInfo? tierOf(String? id) => tiers.where((tier) => tier.id == id).firstOrNull;

  PackageSize? get smallestSize => sizes.firstOrNull;

  PackageType? get defaultPackageType => packageTypeOf(DeliveryRules.defaultPackageTypeId) ?? packageTypes.firstOrNull;

  bool get hasPackageTypes => packageTypes.isNotEmpty;

  bool isTooValuable(Money value) => switch (maxDeclaredValue) {
    final max? => value > max,
    null => false,
  };

  String get premiumTierLabel => tierOf(DeliveryRules.premiumTierId)?.label ?? 'a premium tier';

  bool isHighValue(Money? value) => value != null && value >= highValueThreshold;
}

String _codeOf(JsonReader reader) => reader.strOrNull('id') ?? reader.str('value');

Money _requiredMoney(JsonReader reader, String key) =>
    Money.tryParse(reader.raw[key]) ?? (throw JsonFormatError('Expected an amount at "$key"', reader.raw[key]));

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
  const DeliveryCatalogFailed(this.problem);

  final RideLoadProblem problem;
}

final class DeliveryCatalogReady extends DeliveryCatalogState {
  const DeliveryCatalogReady(this.catalog);

  final DeliveryCatalog catalog;
}
