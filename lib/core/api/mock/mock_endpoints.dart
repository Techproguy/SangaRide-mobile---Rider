class MockEndpoints {
  MockEndpoints._();

  static const String _auth = '/auth';
  static const String _users = '/users';

  static const String requestOtp = '$_auth/otp/request';
  static const String verifyOtp = '$_auth/otp/verify';
  static const String googleSignIn = '$_auth/google';
  static const String appleSignIn = '$_auth/apple';
  static const String refreshToken = '$_auth/refresh';
  static const String logout = '$_auth/logout';

  static const String me = '$_users/me';
}
