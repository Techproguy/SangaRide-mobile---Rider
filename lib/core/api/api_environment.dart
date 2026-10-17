import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/storage_keys.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class ApiEnvironment {
  static bool get usesMock => AppEnvironment.current.usesMockApi;

  static void verify() =>
      AppEnvironment.current.verify(baseUrl: SangaConstants.baseUrl, hasMapsKey: SangaMapsKeys.isConfigured);
}
