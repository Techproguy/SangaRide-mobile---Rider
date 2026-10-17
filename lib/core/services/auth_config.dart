import 'dart:developer';

import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaRegion;

class AuthConfig {
  const AuthConfig({required this.otpLength});

  factory AuthConfig.fromData(Object? data) {
    final otp = JsonReader.of(data).objectOrNull('otp');
    return AuthConfig(otpLength: otp?.intOr('length', fallback.otpLength) ?? fallback.otpLength);
  }

  static const AuthConfig fallback = AuthConfig(otpLength: 6);

  static AuthConfig current = fallback;

  final int otpLength;

  static Future<void> load(ApiService api) async {
    try {
      final response = await api.get(AppEndpoints.authConfig, suppressErrorToast: true);
      current = AuthConfig.fromData(response.dataMap);
      SangaRegion.offerOnly(JsonReader.of(response.dataMap).listOf('countries', (country) => country.str('code')));
    } catch (e) {
      log('auth config failed: $e');
    }
  }
}
