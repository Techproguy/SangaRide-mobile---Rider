import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/auth/get_started_screen.dart';
import 'package:sanga_ride/view/home_widget.dart';

class SangaRoutes {
  SangaRoutes._();

  static const String root = getStarted;

  static const String getStarted = '/get-started';

  static const String home = '/home';
  static const String trips = '/trips';
  static const String wallet = '/wallet';
  static const String profile = '/profile';

  static final List<RouteBase> allRoutes = [...authRoutes, ...homeRoutes];

  static final List<RouteBase> authRoutes = [
    GoRoute(path: getStarted, builder: (context, state) => const GetStartedScreen()),
  ];

  static final List<RouteBase> homeRoutes = [GoRoute(path: home, builder: (context, state) => const HomeWidget())];
}
