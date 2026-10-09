import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/who_for_endpoints.dart';

abstract final class MockWhoFor {
  static const Duration _codeLifetime = Duration(minutes: 5);
  static const int _maxAttempts = 3;

  static final Map<String, _MockVerification> _verifications = {};

  static final List<MockRoute> routes = [
    MockRoute.post(WhoForEndpoints.passengerOtp, _sendCode),
    MockRoute.post(WhoForEndpoints.passengerVerify, _verifyCode),
  ];

  static String _digits(Object? phone) => (phone as String? ?? '').replaceAll(RegExp(r'\D'), '');

  static String _isoNow() => DateTime.now().toUtc().toIso8601String();

  static Object? _sendCode(MockRequest request) {
    final phone = _digits(request.body['phone']);
    if (phone.length < 13) throw const MockFailure(422, 'We can’t text that number.', code: 'invalid_phone');
    if (phone == _digits(MockData.user['phone'])) {
      throw const MockFailure(422, 'That’s your own number.', code: 'own_number');
    }
    final id = 'ver_${_verifications.length + 1}';
    final expiresAt = DateTime.now().add(_codeLifetime);
    _verifications[id] = _MockVerification(expiresAt);
    return {'verificationId': id, 'expiresAt': expiresAt.toUtc().toIso8601String(), 'serverTime': _isoNow()};
  }

  static Object? _verifyCode(MockRequest request) {
    final verification = _verifications[request.body['verificationId']];
    if (verification == null) {
      throw const MockFailure(404, 'We can’t find that code.', code: 'verification_not_found');
    }
    if (DateTime.now().isAfter(verification.expiresAt)) {
      throw const MockFailure(410, 'That code has expired.', code: 'otp_expired');
    }
    if (verification.attemptsLeft == 0) {
      throw const MockFailure(429, 'Too many wrong tries.', code: 'too_many_attempts');
    }
    if (request.body['code'] != MockData.otpCode) {
      verification.attemptsLeft -= 1;
      if (verification.attemptsLeft == 0) {
        throw const MockFailure(429, 'Too many wrong tries.', code: 'too_many_attempts');
      }
      throw MockFailure(
        400,
        'That code didn’t match.',
        code: 'otp_mismatch',
        data: {'attemptsLeft': verification.attemptsLeft},
      );
    }
    return {'verified': true, 'verifiedAt': _isoNow()};
  }
}

class _MockVerification {
  _MockVerification(this.expiresAt);

  final DateTime expiresAt;
  int attemptsLeft = MockWhoFor._maxAttempts;
}
