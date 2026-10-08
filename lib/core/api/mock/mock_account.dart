import 'package:sanga_ride/core/api/account_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_delivery.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip.dart';
import 'package:sanga_ride/core/api/mock/mock_verification.dart';

abstract final class MockAccount {
  static const String takenEmail = 'taken@example.com';
  static const String takenPhone = '+2348022222222';

  static const int _minimumAge = 16;
  static const Duration _otpLifetime = Duration(minutes: 5);
  static const Duration _deletionDelay = Duration(days: 30);

  static final List<MockRoute> routes = [
    MockRoute.get(AccountEndpoints.me, (_) => _json()),
    MockRoute.patch(AccountEndpoints.me, _update),
    MockRoute.delete(AccountEndpoints.me, _delete),
    MockRoute.post(AccountEndpoints.photo, _photo),
    MockRoute.post(AccountEndpoints.phone, _requestPhone),
    MockRoute.post(AccountEndpoints.phoneVerify, _verifyPhone),
  ];

  static final DateTime _memberSince = DateTime.now().subtract(const Duration(days: 430));
  static final Map<String, dynamic> _fields = {
    'id': MockData.user['id'],
    'firstName': MockData.user['firstName'],
    'lastName': MockData.user['lastName'],
    'phone': MockData.user['phone'],
    'email': MockData.user['email'],
    'dateOfBirth': '1996-04-12',
    'photoUrl': MockData.user['photoUrl'],
    'rating': MockData.user['rating'],
    'ridesCount': MockData.user['ridesCount'],
  };
  static String? _pendingPhone;
  static DateTime? _codeSentAt;

  static String get firstName => '${_fields['firstName']}';

  static Map<String, dynamic> _json() => {
    ..._fields,
    'memberSince': _memberSince.toUtc().toIso8601String(),
    'verification': {'status': MockVerification.accountStatus(DateTime.now())},
    'serverTime': DateTime.now().toUtc().toIso8601String(),
  };

  static Object? _update(MockRequest request) {
    final body = request.body;
    if (body.containsKey('firstName') || body.containsKey('lastName')) {
      final first = '${body['firstName'] ?? _fields['firstName']}'.trim();
      final last = '${body['lastName'] ?? _fields['lastName']}'.trim();
      if (first.isEmpty || last.isEmpty) {
        throw const MockFailure(422, 'Add your first and last name.', code: 'name_required');
      }
      _fields['firstName'] = first;
      _fields['lastName'] = last;
    }
    if (body.containsKey('email')) _fields['email'] = _validEmail('${body['email']}'.trim());
    final birthday = body['dateOfBirth'] ?? body['birthday'];
    if (birthday != null) _fields['dateOfBirth'] = _validBirthday('$birthday');
    return _json();
  }

  static String _validEmail(String email) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw const MockFailure(422, 'That email doesn’t look right.', code: 'invalid_email');
    }
    if (email.toLowerCase() == takenEmail) {
      throw const MockFailure(409, 'Another account already uses that email.', code: 'email_taken');
    }
    return email;
  }

  static String _validBirthday(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) throw const MockFailure(422, 'That date doesn’t look right.', code: 'invalid_date');
    final now = DateTime.now();
    final cutoff = DateTime(now.year - _minimumAge, now.month, now.day);
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    if (day.isAfter(cutoff)) throw const MockFailure(422, 'You need to be at least 16.', code: 'too_young');
    return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  static Object? _photo(MockRequest request) {
    final url = MockDelivery.uploadUrlOf('${request.body['uploadId']}') ?? MockDelivery.profilePhotoAsset;
    _fields['photoUrl'] = url;
    return _json();
  }

  static String _digits(Object? value) => '$value'.replaceAll(RegExp(r'\D'), '');

  static Object? _requestPhone(MockRequest request) {
    final phone = '${request.body['phone']}';
    if (!RegExp(r'^\+234[789]\d{9}$').hasMatch(phone)) {
      throw const MockFailure(422, 'Enter a valid Nigerian phone number.', code: 'invalid_phone');
    }
    if (_digits(phone) == _digits(_fields['phone'])) {
      throw const MockFailure(422, 'That’s the number you already use.', code: 'same_phone');
    }
    if (phone == takenPhone) throw const MockFailure(409, 'This number already has an account.', code: 'phone_taken');
    _pendingPhone = phone;
    _codeSentAt = DateTime.now();
    return {'phone': phone, 'expiresInSeconds': _otpLifetime.inSeconds, 'code': 'otp_sent'};
  }

  static Object? _verifyPhone(MockRequest request) {
    final pending = _pendingPhone;
    final sentAt = _codeSentAt;
    if (pending == null || sentAt == null || pending != request.body['phone']) {
      throw const MockFailure(400, 'That code didn’t match.', code: 'otp_mismatch');
    }
    if (DateTime.now().difference(sentAt) > _otpLifetime) {
      throw const MockFailure(400, 'That code has expired.', code: 'otp_expired');
    }
    if (request.body['code'] != MockData.otpCode) {
      throw const MockFailure(400, 'That code didn’t match.', code: 'otp_mismatch');
    }
    _fields['phone'] = pending;
    _pendingPhone = null;
    _codeSentAt = null;
    return _json();
  }

  static Object? _delete(MockRequest request) {
    if (_hasActiveTrip()) {
      throw const MockFailure(409, 'Finish your current trip first.', code: 'active_trip');
    }
    return {'deletesAt': DateTime.now().add(_deletionDelay).toUtc().toIso8601String()};
  }

  static bool _hasActiveTrip() {
    final route = MockTrip.routes.where((route) => route.match('GET', MockEndpoints.activeTrip) != null).firstOrNull;
    final request = MockRequest(path: MockEndpoints.activeTrip, body: const {}, query: const {}, params: const {});
    return route?.handler(request) != null;
  }
}
