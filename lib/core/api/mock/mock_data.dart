class MockData {
  MockData._();

  static const String otpCode = '123456';

  static const Map<String, dynamic> tokens = {'accessToken': 'mock-access-token', 'refreshToken': 'mock-refresh-token'};

  static const Map<String, dynamic> user = {
    'id': 'usr_rider_001',
    'firstName': 'Ada',
    'lastName': 'Okafor',
    'email': 'ada.okafor@example.com',
    'phone': '+2348012345678',
    'avatarUrl': null,
    'rating': 4.9,
    'tripCount': 37,
  };
}
