import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/nav_key.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/nav_observer.dart';
import 'package:sanga_ride/view/widgets/widgets.dart';

class SangaRouter {
  SangaRouter._();

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: SangaRoutes.root,
    debugLogDiagnostics: kDebugMode,
    observers: [SangaNavObserver()],
    routes: SangaRoutes.allRoutes,
    errorBuilder: (context, state) => const ErrorScreen(),
  );

  static void resetHome() => router.go(SangaRoutes.home);
}
