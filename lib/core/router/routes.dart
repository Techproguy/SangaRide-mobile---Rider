import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/auth/about_you_screen.dart';
import 'package:sanga_ride/view/auth/home_location_screen.dart';
import 'package:sanga_ride/view/auth/onboarding_screen.dart';
import 'package:sanga_ride/view/auth/selfie_screen.dart';
import 'package:sanga_ride/view/auth/sign_in_screen.dart';
import 'package:sanga_ride/view/auth/sign_up_screen.dart';
import 'package:sanga_ride/view/auth/verify_otp_screen.dart';
import 'package:sanga_ride/view/home/rider_home_screen.dart';
import 'package:sanga_ride/view/ride/fare_breakdown_screen.dart';
import 'package:sanga_ride/view/ride/matching/confirm_driver_screen.dart';
import 'package:sanga_ride/view/ride/matching/ride_offers_screen.dart';
import 'package:sanga_ride/view/ride/ride_options_screen.dart';
import 'package:sanga_ride/view/ride/ride_preferences_screen.dart';
import 'package:sanga_ride/view/ride/ride_pricing_screen.dart';
import 'package:sanga_ride/view/ride/ride_review_screen.dart';
import 'package:sanga_ride/view/ride/ride_route_screen.dart';
import 'package:sanga_ride/view/ride/ride_search_screen.dart';
import 'package:sanga_ride/view/ride/ride_timing_screen.dart';
import 'package:sanga_ride/view/ride/trip_type_screen.dart';

class SangaRoutes {
  SangaRoutes._();

  static const String root = onboarding;

  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String verifyOtp = '/verify-otp';
  static const String signUp = '/sign-up';
  static const String aboutYou = '/sign-up/about-you';
  static const String selfie = '/sign-up/selfie';
  static const String homeLocation = '/sign-up/home';

  static const String rideSearch = '/ride/search';
  static const String rideRoute = '/ride/route';
  static const String tripType = '/ride/trip-type';
  static const String rideOptions = '/ride/options';
  static const String ridePreferences = '/ride/preferences';
  static const String ridePricing = '/ride/pricing';
  static const String rideFare = '/ride/fare';
  static const String rideTiming = '/ride/when';
  static const String rideReview = '/ride/review';
  static const String rideOffers = '/ride/offers';
  static const String rideConfirmDriver = '/ride/confirm-driver';

  static const String home = '/home';

  static final List<RouteBase> allRoutes = [...authRoutes, ...homeRoutes, ...rideRoutes];

  static final List<RouteBase> rideRoutes = [
    GoRoute(path: rideSearch, builder: (context, state) => const RideSearchScreen()),
    GoRoute(path: rideRoute, builder: (context, state) => const RideRouteScreen()),
    GoRoute(path: tripType, builder: (context, state) => const TripTypeScreen()),
    GoRoute(path: rideOptions, builder: (context, state) => const RideOptionsScreen()),
    GoRoute(path: ridePreferences, builder: (context, state) => const RidePreferencesScreen()),
    GoRoute(path: ridePricing, builder: (context, state) => const RidePricingScreen()),
    GoRoute(path: rideFare, builder: (context, state) => const FareBreakdownScreen()),
    GoRoute(path: rideTiming, builder: (context, state) => const RideTimingScreen()),
    GoRoute(path: rideReview, builder: (context, state) => const RideReviewScreen()),
    GoRoute(path: rideOffers, builder: (context, state) => const RideOffersScreen()),
    GoRoute(path: rideConfirmDriver, builder: (context, state) => const ConfirmDriverScreen()),
  ];

  static final List<RouteBase> authRoutes = [
    GoRoute(path: onboarding, builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: signIn, builder: (context, state) => const SignInScreen()),
    GoRoute(path: signUp, builder: (context, state) => const SignUpScreen()),
    GoRoute(path: aboutYou, builder: (context, state) => const AboutYouScreen()),
    GoRoute(path: selfie, builder: (context, state) => const SelfieScreen()),
    GoRoute(path: homeLocation, builder: (context, state) => const HomeLocationScreen()),
    GoRoute(path: verifyOtp, builder: (context, state) => VerifyOtpScreen(state.extra as OtpArgs)),
  ];

  static final List<RouteBase> homeRoutes = [GoRoute(path: home, builder: (context, state) => const RiderHomeScreen())];
}
