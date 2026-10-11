import 'package:get_storage/get_storage.dart';
import 'package:sanga_ride/core/storage_keys.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class RegionMemory {
  static final GetStorage _storage = GetStorage();

  static void restore() => SangaRegion.current =
      SangaRegion.ofIsoCode(_storage.read<String>(SangaStorageKeys.region)) ?? SangaRegion.fallback;

  static void apply(SangaRegion region) {
    SangaRegion.current = region;
    _storage.write(SangaStorageKeys.region, region.isoCode);
  }

  static void applyPhone(String? phone) {
    final region = SangaRegion.ofPhone(phone);
    if (region != null) apply(region);
  }
}
