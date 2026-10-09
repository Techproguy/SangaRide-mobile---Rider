import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
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
  Timer? _spinnerTimer;
  bool _showsSpinner = false;

  @override
  void initState() {
    super.initState();
    _spinnerTimer = Timer(BootScreen.spinnerDelay, _revealSpinner);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_restoreAndLeave()));
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  void _revealSpinner() {
    if (mounted) setState(() => _showsSpinner = true);
  }

  Future<void> _restoreAndLeave() async {
    final stack = await _restore.resolveBoot();
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
            Image.asset(AppAssets.bootSplash, fit: BoxFit.cover, gaplessPlayback: true),
            if (_showsSpinner)
              Align(
                alignment: const Alignment(0, _spinnerAlignmentY),
                child: const SangaActivityIndicator(
                  size: _spinnerSize,
                  color: Colors.white,
                ).animate().fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve),
              ),
          ],
        ),
      ),
    );
  }
}
