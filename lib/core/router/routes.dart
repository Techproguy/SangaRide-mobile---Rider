import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/auth/onboarding_screen.dart';
import 'package:sanga_ride/view/auth/sign_in_screen.dart';
import 'package:sanga_ride/view/auth/verify_otp_screen.dart';
import 'package:sanga_ride/view/home_widget.dart';

class SangaRoutes {
  SangaRoutes._();

  static const String root = onboarding;

  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String verifyOtp = '/verify-otp';

  static const String home = '/home';
  static const String trips = '/trips';
  static const String wallet = '/wallet';
  static const String profile = '/profile';

  static final List<RouteBase> allRoutes = [...authRoutes, ...homeRoutes];

  static final List<RouteBase> authRoutes = [
    GoRoute(path: onboarding, builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: signIn, builder: (context, state) => const SignInScreen()),
    GoRoute(
      path: verifyOtp,
      builder: (context, state) => VerifyOtpScreen(phone: state.extra as String),
    ),
  ];

  static final List<RouteBase> homeRoutes = [GoRoute(path: home, builder: (context, state) => const HomeWidget())];
}
