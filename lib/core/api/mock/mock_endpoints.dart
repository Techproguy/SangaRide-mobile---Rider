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

  static const String activeTrip = '/trips/active';
  static const String _liveTrip = '/trips/:id';

  static const String liveTrip = _liveTrip;
  static const String liveTripConfirmDetails = '$_liveTrip/details/confirm';
  static const String liveTripPinRefresh = '$_liveTrip/pin/refresh';
  static const String liveTripReport = '$_liveTrip/report';
  static const String liveTripComplete = '$_liveTrip/complete';
  static const String liveTripCall = '$_liveTrip/call';
  static const String liveTripMessages = '$_liveTrip/messages';
  static const String liveTripEvents = '$_liveTrip/events';
  static const String liveTripStopsQuote = '$_liveTrip/stops/quote';
  static const String liveTripStops = '$_liveTrip/stops';
  static const String liveTripCancellation = '$_liveTrip/cancellation';
  static const String liveTripCancel = '$_liveTrip/cancel';

  static String liveTripOf(String id) => liveTrip.replaceFirst(':id', id);

  static String liveTripConfirmDetailsOf(String id) => liveTripConfirmDetails.replaceFirst(':id', id);

  static String liveTripPinRefreshOf(String id) => liveTripPinRefresh.replaceFirst(':id', id);

  static String liveTripReportOf(String id) => liveTripReport.replaceFirst(':id', id);

  static String liveTripCompleteOf(String id) => liveTripComplete.replaceFirst(':id', id);

  static String liveTripCallOf(String id) => liveTripCall.replaceFirst(':id', id);

  static String liveTripMessagesOf(String id) => liveTripMessages.replaceFirst(':id', id);

  static String liveTripEventsOf(String id) => liveTripEvents.replaceFirst(':id', id);

  static String liveTripStopsQuoteOf(String id) => liveTripStopsQuote.replaceFirst(':id', id);

  static String liveTripStopsOf(String id) => liveTripStops.replaceFirst(':id', id);

  static String liveTripCancellationOf(String id) => liveTripCancellation.replaceFirst(':id', id);

  static String liveTripCancelOf(String id) => liveTripCancel.replaceFirst(':id', id);

  static const String _tripWrapUp = '/trips/:id';

  static const String tripPayment = '$_tripWrapUp/payment';
  static const String tripPaymentCancel = '$_tripWrapUp/payment/cancel';
  static const String tripReceipt = '$_tripWrapUp/receipt';
  static const String tripRating = '$_tripWrapUp/rating';

  static String tripPaymentOf(String id) => tripPayment.replaceFirst(':id', id);

  static String tripPaymentCancelOf(String id) => tripPaymentCancel.replaceFirst(':id', id);

  static String tripReceiptOf(String id) => tripReceipt.replaceFirst(':id', id);

  static String tripRatingOf(String id) => tripRating.replaceFirst(':id', id);
}
