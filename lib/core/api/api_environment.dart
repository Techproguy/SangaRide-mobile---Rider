import 'package:flutter/foundation.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/storage_keys.dart';

abstract final class ApiEnvironment {
  static const String mode = String.fromEnvironment('SANGA_API', defaultValue: kReleaseMode ? 'live' : 'mock');

  static const bool usesMock = mode == 'mock';

  static void verify() {
    if (usesMock) return;
    if (SangaConstants.baseUrl.isEmpty) throw StateError('BASE_URL is not set for a live build.');
    if (!SangaMapsKeys.isConfigured) throw StateError('The Maps key is not set for a live build.');
  }
}
