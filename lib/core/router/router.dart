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
    if (SessionStorage.tokens.hasSession) return null;
    final isSignUpResume =
        state.uri.path == SangaRoutes.signUp && state.uri.queryParameters.containsKey(SangaRoutes.stepParam);
    if (isSignUpResume) return SangaRoutes.onboarding;
    return SangaRoutes.publicPaths.contains(state.uri.path) ? null : SangaRoutes.onboarding;
  }

  static String get currentPath => router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation ?? '';

  static void switchTo(BuildContext context, String path, {Object? extra}) {
    final matches = router.routerDelegate.currentConfiguration.matches;
    final below = matches.length > 1 ? matches[matches.length - 2].matchedLocation : null;
    if (extra == null && below == path && context.canPop()) return context.pop();
    context.push(path, extra: extra);
  }
}
