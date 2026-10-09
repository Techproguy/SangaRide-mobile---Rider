import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/safety_config.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/connectivity_service.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/view/boot/live_activities.dart';
import 'package:sanga_ride/view/safety/widgets/dial_number.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class AppOverlays extends StatefulWidget {
  const AppOverlays({super.key, required this.child});

  final Widget child;

  @override
  State<AppOverlays> createState() => _AppOverlaysState();
}

class _AppOverlaysState extends State<AppOverlays> {
  final _connectivity = Get.find<ConnectivityService>();
  final _restore = Get.find<SessionRestore>();
  final ValueNotifier<String> _path = ValueNotifier(SangaRouter.currentPath);
  final ValueNotifier<bool> _bannerOccupiesTop = ValueNotifier(false);
  Timer? _bannerRelease;

  @override
  void initState() {
    super.initState();
    SangaRouter.router.routerDelegate.addListener(_onRouteChanged);
    _connectivity.bannerState.addListener(_onBannerState);
  }

  @override
  void dispose() {
    SangaRouter.router.routerDelegate.removeListener(_onRouteChanged);
    _connectivity.bannerState.removeListener(_onBannerState);
    _bannerRelease?.cancel();
    _path.dispose();
    _bannerOccupiesTop.dispose();
    super.dispose();
  }

  void _onRouteChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final next = SangaRouter.currentPath;
      final previous = _path.value;
      if (next == previous) return;
      _path.value = next;
      if (next == SangaRoutes.home) unawaited(_restore.refreshIfStale());
    });
  }

  void _onBannerState() {
    _bannerRelease?.cancel();
    if (_connectivity.bannerState.value != SangaConnectionState.online) {
      _bannerOccupiesTop.value = true;
      return;
    }
    _bannerRelease = Timer(SangaConnectionBanner.recoveredHold + SangaMotion.morph, () {
      _bannerOccupiesTop.value = false;
    });
  }

  void _actOnActivity(SangaLiveActivity activity) {
    if (activity.id == LiveActivities.sosId) unawaited(dialNumber(SafetyConfig.emergencyNumber));
  }

  void _openActivity(SangaLiveActivity activity) {
    final route = LiveActivities.routeFor(activity.id, _restore.meState);
    if (route != null) unawaited(SangaRouter.router.push<Object?>(route));
  }

  @override
  Widget build(BuildContext context) {
    return SangaTopOverlayHost(
      content: widget.child,
      overlay: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SangaConnectionBanner(state: _connectivity.bannerState),
          ValueListenableBuilder<bool>(
            valueListenable: _bannerOccupiesTop,
            builder: (context, occupied, _) => _withoutTopInset(
              context,
              isRemoved: occupied,
              child: ValueListenableBuilder<String>(
                valueListenable: _path,
                builder: (context, path, _) => Obx(
                  () => SangaLiveActivityBar(
                    activities: LiveActivities.from(_restore.meStateRx.value, path),
                    onTap: _openActivity,
                    onAction: _actOnActivity,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _withoutTopInset(BuildContext context, {required bool isRemoved, required Widget child}) {
    if (!isRemoved) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(padding: media.padding.copyWith(top: 0)),
      child: child,
    );
  }
}
