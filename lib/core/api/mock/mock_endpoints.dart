class MockEndpoints {
  MockEndpoints._();

  static const String _auth = '/auth';
  static const String _users = '/users';
  static const String _verification = '/verification';

  static const String signUp = '$_auth/sign-up';
  static const String checkExistence = '$_auth/check-existence';
  static const String requestOtp = '$_auth/otp/request';
  static const String verifyOtp = '$_auth/otp/verify';
  static const String googleSignIn = '$_auth/google';
  static const String appleSignIn = '$_auth/apple';
  static const String refreshToken = '$_auth/refresh';
  static const String logout = '$_auth/logout';

  static const String me = '$_users/me';
  static const String homeAddress = '$_users/me/places/home';

  static const String selfie = '$_verification/selfie';

  static const String recentPlaces = '$_users/me/places/recent';
  static const String recentPlace = '$_users/me/places/recent/:id';
  static const String savedPlaces = '$_users/me/places';
  static const String weather = '/weather';

  static String recentPlaceOf(String id) => recentPlace.replaceFirst(':id', id);

  static const String rideOptions = '/rides/options';
  static const String rideEstimate = '/rides/estimate';
}
