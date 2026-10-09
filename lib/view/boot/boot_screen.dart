import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/view/boot/app_splash.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  static const Duration spinnerDelay = Duration(milliseconds: 600);

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  static const double _spinnerSize = 28;
  static const double _spinnerAlignmentY = 0.12;

  final _restore = Get.find<SessionRestore>();
  final Completer<void> _splashDone = Completer<void>();
  Timer? _spinnerTimer;
  bool _showsSpinner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_restoreAndLeave()));
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  void _onSplashFinished() {
    if (!_splashDone.isCompleted) _splashDone.complete();
    _spinnerTimer = Timer(BootScreen.spinnerDelay, () {
      if (mounted) setState(() => _showsSpinner = true);
    });
  }

  Future<void> _restoreAndLeave() async {
    final pending = _restore.resolveBoot();
    await _splashDone.future;
    final stack = await pending;
    if (!mounted) return;
    if (!SessionStorage.tokens.hasSession) {
      SangaRouter.router.go(SangaRoutes.onboarding);
      return;
    }
    await _restore.open(stack);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onPhoto,
      child: Scaffold(
        backgroundColor: SangaColors.primary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SangaSplashSequence(scene: AppSplash.scene, onFinished: _onSplashFinished),
            if (_showsSpinner)
              Align(
                alignment: const Alignment(0, _spinnerAlignmentY),
                child: const SangaActivityIndicator(
                  size: _spinnerSize,
                  color: SangaColors.onPrimary,
                ).animate().fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve),
              ),
          ],
        ),
      ),
    );
  }
}
