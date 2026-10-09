import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/nav_key.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/services/crash_reporter.dart';
import 'package:sanga_ride/initialize.dart';
import 'package:sanga_ride/view/boot/app_overlays.dart';
import 'package:sanga_ride/view/boot/session_end_notice.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show SessionEndReason, SessionHub;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

void main() {
  runZonedGuarded(_start, CrashReporting.recordZoneError);
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  CrashReporting.install();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeSanga();
  runApp(const SangaRide());
}

class SangaRide extends StatefulWidget {
  const SangaRide({super.key});

  @override
  State<SangaRide> createState() => _SangaRideState();
}

class _SangaRideState extends State<SangaRide> {
  StreamSubscription<SessionEndReason>? _sessionEnded;

  @override
  void initState() {
    super.initState();
    SangaToast.install(navigatorKey);
    _sessionEnded = SessionHub.instance.ended.listen((reason) => unawaited(SessionEndPresenter.present(reason)));
  }

  @override
  void dispose() {
    _sessionEnded?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: SangaConstants.appName,
      routerConfig: SangaRouter.router,
      theme: SangaTheme.light,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => SangaFrame(
        config: SangaConstants.frame,
        child: AppOverlays(child: child!),
      ),
    );
  }
}
