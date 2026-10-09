import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/router/dev_routes.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DevEntry extends StatelessWidget {
  const DevEntry({super.key, required this.child});

  static const double _zoneHeight = 44;
  static const double _sideInset = 72;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    final top = MediaQuery.paddingOf(context).top + SangaSpacing.md;
    return Stack(
      children: [
        child,
        Positioned(
          top: top,
          left: _sideInset,
          right: _sideInset,
          height: _zoneHeight,
          child: GestureDetector(behavior: HitTestBehavior.translucent, onLongPress: () => context.push(DevRoutes.dev)),
        ),
      ],
    );
  }
}
