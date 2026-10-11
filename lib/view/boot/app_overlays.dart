import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/connectivity_service.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/view/boot/live_activities.dart';
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

  @override
  void initState() {
    super.initState();
    SangaRouter.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    SangaRouter.router.routerDelegate.removeListener(_onRouteChanged);
    _path.dispose();
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

  void _openActivity(SangaLiveActivity activity) {
    final route = LiveActivities.routeFor(activity.id, _restore.meState);
    if (route != null) unawaited(SangaRouter.router.push<Object?>(route));
  }

  @override
  Widget build(BuildContext context) {
    return SangaTopOverlayHost(
      content: widget.child,
      overlay: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SangaConnectionBanner(
              state: _connectivity.bannerState,
              onShownChanged: (shown) => _connectivity.bannerShown.value = shown,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _connectivity.bannerShown,
              builder: (context, isBannerShown, _) => ValueListenableBuilder<String>(
                valueListenable: _path,
                builder: (context, path, _) => Obx(
                  () => SangaLiveActivityBar(
                    avoidStatusBar: !isBannerShown,
                    activities: LiveActivities.from(_restore.meStateRx.value, path),
                    onTap: _openActivity,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
