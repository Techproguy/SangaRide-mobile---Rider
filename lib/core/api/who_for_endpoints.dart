import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class WhoForEndpoints {
  static const String passengerOtp = '/rides/passengers';
  static const String passengerResend = '/rides/passengers/:id/otp/resend';
  static const String passengerVerify = '/rides/passengers/:id/otp/verify';

  static String passengerResendOf(String id) => fillPath(passengerResend, {'id': id});

  static String passengerVerifyOf(String id) => fillPath(passengerVerify, {'id': id});
}
