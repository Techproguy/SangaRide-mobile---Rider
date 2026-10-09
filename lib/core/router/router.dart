import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/view/widgets/widgets.dart';

class SangaRouter {
  SangaRouter._();

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: SessionStorage.tokens.hasSession ? SangaRoutes.boot : SangaRoutes.onboarding,
    debugLogDiagnostics: kDebugMode,
    observers: [SangaNavObserver()],
    routes: SangaRoutes.allRoutes,
    redirect: _guard,
    errorBuilder: (context, state) => const ErrorScreen(),
  );

  static String? _guard(BuildContext context, GoRouterState state) {
    final isPublic = SangaRoutes.publicPaths.contains(state.uri.path);
    if (isPublic || SessionStorage.tokens.hasSession) return null;
    return SangaRoutes.onboarding;
  }

  static String get currentPath => router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation ?? '';
}
