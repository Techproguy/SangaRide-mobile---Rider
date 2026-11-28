import 'dart:async';
import 'dart:developer';

import 'package:get_storage/get_storage.dart';

import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/services/rider_config.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaRegion;

class AuthConfig {
  const AuthConfig({this.otpLength});

  factory AuthConfig.fromData(Object? data) {
    final length = JsonReader.of(data).objectOrNull('otp')?.intOrNull('length');
    return AuthConfig(otpLength: length != null && length > 0 ? length : null);
  }

  static const String _storageKey = 'auth_config';

  static AuthConfig current = const AuthConfig();

  final int? otpLength;

  static void restore() => current = AuthConfig.fromData(GetStorage().read<Object?>(_storageKey));

  static int requireOtpLength() => current.otpLength ?? (throw StateError('OTP length not loaded'));

  static Future<void> ensureOtpLength(ApiService api) async {
    if (current.otpLength == null) await load(api);
    requireOtpLength();
  }

  static Future<void> load(ApiService api) async {
    try {
      final response = await api.get(AppEndpoints.authConfig, suppressErrorToast: true);
      final received = AuthConfig.fromData(response.dataMap);
      if (received.otpLength != null) {
        current = received;
        unawaited(GetStorage().write(_storageKey, response.dataMap));
      }
      LegalLinks.apply(JsonReader.of(response.dataMap).objectOrNull('legal'));
      SangaRegion.offerOnly(JsonReader.of(response.dataMap).listOf('countries', (country) => country.str('code')));
    } catch (e) {
      log('auth config failed: $e');
    }
  }

  static Future<void> loadServerConfig(ApiService api) async {
    try {
      final response = await api.get(AppEndpoints.config, suppressErrorToast: true);
      LegalLinks.apply(JsonReader.of(response.dataMap).objectOrNull('legal'));
      ServerConfig.apply(response.dataMap);
      RiderConfig.apply(response.dataMap);
    } catch (e) {
      log('server config failed: $e');
    }
  }
}
