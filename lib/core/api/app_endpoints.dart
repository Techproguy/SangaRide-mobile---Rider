import 'package:sanga_ride/core/api/account_endpoints.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class AppEndpoints {
  AppEndpoints._();

  static const String _auth = '/auth';
  static const String _users = '/users';

  static const String signUp = '$_auth/sign-up';
  static const String checkExistence = '$_auth/check-existence';
  static const String requestOtp = '$_auth/otp/request';
  static const String verifyOtp = '$_auth/otp/verify';
  static const String googleSignIn = '$_auth/google';
  static const String appleSignIn = '$_auth/apple';
  static const String refreshToken = '$_auth/refresh';
  static const String logout = '$_auth/logout';

  static const String me = AccountEndpoints.me;
  static const String meState = '/me/state';
  static const String health = '/health';

  static const String recentPlaces = '$_users/me/places/recent';
  static const String recentPlace = '$_users/me/places/recent/:id';
  static const String weather = '/weather';

  static String recentPlaceOf(String id) => fillPath(recentPlace, {'id': id});

  static const String rideOptions = '/rides/options';
  static const String rideEstimate = '/rides/estimate';

  static const String rideRequests = '/rides/requests';
  static const String _rideRequest = '/rides/requests/:id';
  static const String _rideOffer = '/rides/requests/:id/offers/:offerId';

  static const String rideRequest = _rideRequest;
  static const String rideRequestOffers = '$_rideRequest/offers';
  static const String rideRequestHold = '$_rideRequest/hold';
  static const String rideRequestCancel = '$_rideRequest/cancel';
  static const String rideOfferIgnore = '$_rideOffer/ignore';
  static const String rideOfferHold = '$_rideOffer/hold';
  static const String rideOfferConfirm = '$_rideOffer/confirm';

  static String rideRequestOf(String id) => fillPath(rideRequest, {'id': id});

  static String rideRequestOffersOf(String id) => fillPath(rideRequestOffers, {'id': id});

  static String rideRequestHoldOf(String id) => fillPath(rideRequestHold, {'id': id});

  static String rideRequestCancelOf(String id) => fillPath(rideRequestCancel, {'id': id});

  static String rideOfferIgnoreOf(String id, String offerId) => _offerPath(rideOfferIgnore, id, offerId);

  static String rideOfferHoldOf(String id, String offerId) => _offerPath(rideOfferHold, id, offerId);

  static String rideOfferConfirmOf(String id, String offerId) => _offerPath(rideOfferConfirm, id, offerId);

  static String _offerPath(String template, String id, String offerId) =>
      fillPath(template, {'id': id, 'offerId': offerId});

  static const String activeTrip = '/trips/active';
  static const String _liveTrip = '/trips/:id';

  static const String liveTrip = _liveTrip;
  static const String liveTripConfirmDetails = '$_liveTrip/details/confirm';
  static const String liveTripPinRefresh = '$_liveTrip/pin/refresh';
  static const String liveTripReport = '$_liveTrip/report';
  static const String liveTripComplete = '$_liveTrip/complete';
  static const String liveTripCall = '$_liveTrip/call';
  static const String liveTripMessages = '$_liveTrip/messages';
  static const String liveTripStopsQuote = '$_liveTrip/stops/quote';
  static const String liveTripStops = '$_liveTrip/stops';
  static const String liveTripCancellation = '$_liveTrip/cancellation';
  static const String liveTripCancel = '$_liveTrip/cancel';

  static String liveTripOf(String id) => fillPath(liveTrip, {'id': id});

  static String liveTripConfirmDetailsOf(String id) => fillPath(liveTripConfirmDetails, {'id': id});

  static String liveTripPinRefreshOf(String id) => fillPath(liveTripPinRefresh, {'id': id});

  static String liveTripReportOf(String id) => fillPath(liveTripReport, {'id': id});

  static String liveTripCompleteOf(String id) => fillPath(liveTripComplete, {'id': id});

  static String liveTripCallOf(String id) => fillPath(liveTripCall, {'id': id});

  static String liveTripMessagesOf(String id) => fillPath(liveTripMessages, {'id': id});

  static String liveTripStopsQuoteOf(String id) => fillPath(liveTripStopsQuote, {'id': id});

  static String liveTripStopsOf(String id) => fillPath(liveTripStops, {'id': id});

  static String liveTripCancellationOf(String id) => fillPath(liveTripCancellation, {'id': id});

  static String liveTripCancelOf(String id) => fillPath(liveTripCancel, {'id': id});

  static const String _tripWrapUp = '/trips/:id';

  static const String tripPayment = '$_tripWrapUp/payment';
  static const String tripPaymentCancel = '$_tripWrapUp/payment/cancel';
  static const String tripReceipt = '$_tripWrapUp/receipt';
  static const String tripRating = '$_tripWrapUp/rating';
  static const String tripShare = '$_tripWrapUp/share';

  static String tripPaymentOf(String id) => fillPath(tripPayment, {'id': id});

  static String tripPaymentCancelOf(String id) => fillPath(tripPaymentCancel, {'id': id});

  static String tripReceiptOf(String id) => fillPath(tripReceipt, {'id': id});

  static String tripRatingOf(String id) => fillPath(tripRating, {'id': id});

  static String tripShareOf(String id) => fillPath(tripShare, {'id': id});
}
