import 'package:flutter/material.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show SessionEndReason, navigatorKey;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SessionEndNotice {
  const SessionEndNotice({required this.title, required this.message});

  final String title;
  final String message;

  static const Map<SessionEndReason, SessionEndNotice> copy = {
    SessionEndReason.expired: SessionEndNotice(
      title: 'Signed out',
      message: 'Your session timed out. Sign in again to pick up where you left off.',
    ),
    SessionEndReason.suspended: SessionEndNotice(
      title: 'Account paused',
      message: 'Your account is paused. Our team will reach out.',
    ),
    SessionEndReason.otherDevice: SessionEndNotice(
      title: 'Signed out',
      message: 'You signed in on another phone, so we signed you out here.',
    ),
  };
}

abstract final class SessionEndPresenter {
  static Future<void> present(SessionEndReason reason) async {
    final overlayContext = navigatorKey.currentState?.overlay?.context;
    if (overlayContext != null) {
      Navigator.of(overlayContext).popUntil((route) => route is! PopupRoute);
    }
    SangaRouter.router.go(SangaRoutes.onboarding);
    final notice = SessionEndNotice.copy[reason];
    if (notice == null) return;
    await WidgetsBinding.instance.endOfFrame;
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null || !context.mounted) return;
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.caution,
      title: notice.title,
      message: notice.message,
      actionLabel: 'Got it',
    );
  }
}
