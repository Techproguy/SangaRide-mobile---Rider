import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/auth/about_you_screen.dart';
import 'package:sanga_ride/view/auth/home_location_screen.dart';
import 'package:sanga_ride/view/auth/onboarding_screen.dart';
import 'package:sanga_ride/view/auth/selfie_screen.dart';
import 'package:sanga_ride/view/auth/sign_in_screen.dart';
import 'package:sanga_ride/view/auth/sign_up_screen.dart';
import 'package:sanga_ride/view/auth/verify_otp_screen.dart';
import 'package:sanga_ride/view/home_widget.dart';

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

  static const String home = '/home';
  static const String trips = '/trips';
  static const String wallet = '/wallet';
  static const String profile = '/profile';

  static final List<RouteBase> allRoutes = [...authRoutes, ...homeRoutes];

  static final List<RouteBase> authRoutes = [
    GoRoute(path: onboarding, builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: signIn, builder: (context, state) => const SignInScreen()),
    GoRoute(path: signUp, builder: (context, state) => const SignUpScreen()),
    GoRoute(path: aboutYou, builder: (context, state) => const AboutYouScreen()),
    GoRoute(path: selfie, builder: (context, state) => const SelfieScreen()),
    GoRoute(path: homeLocation, builder: (context, state) => const HomeLocationScreen()),
    GoRoute(path: verifyOtp, builder: (context, state) => VerifyOtpScreen(state.extra as OtpArgs)),
  ];

  static final List<RouteBase> homeRoutes = [GoRoute(path: home, builder: (context, state) => const HomeWidget())];
}
