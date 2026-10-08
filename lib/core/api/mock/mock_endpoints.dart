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

  static const String rideRequests = '/rides/requests';
  static const String rideRequestsScheduled = '/rides/requests/scheduled';
  static const String _rideRequest = '/rides/requests/:id';
  static const String _rideOffer = '/rides/requests/:id/offers/:offerId';

  static const String rideRequest = _rideRequest;
  static const String rideRequestOffers = '$_rideRequest/offers';
  static const String rideRequestHold = '$_rideRequest/hold';
  static const String rideRequestCancel = '$_rideRequest/cancel';
  static const String rideOfferIgnore = '$_rideOffer/ignore';
  static const String rideOfferHold = '$_rideOffer/hold';
  static const String rideOfferConfirm = '$_rideOffer/confirm';

  static String rideRequestOf(String id) => rideRequest.replaceFirst(':id', id);

  static String rideRequestOffersOf(String id) => rideRequestOffers.replaceFirst(':id', id);

  static String rideRequestHoldOf(String id) => rideRequestHold.replaceFirst(':id', id);

  static String rideRequestCancelOf(String id) => rideRequestCancel.replaceFirst(':id', id);

  static String rideOfferIgnoreOf(String id, String offerId) => _offerPath(rideOfferIgnore, id, offerId);

  static String rideOfferHoldOf(String id, String offerId) => _offerPath(rideOfferHold, id, offerId);

  static String rideOfferConfirmOf(String id, String offerId) => _offerPath(rideOfferConfirm, id, offerId);

  static String _offerPath(String template, String id, String offerId) =>
      template.replaceFirst(':id', id).replaceFirst(':offerId', offerId);
}
