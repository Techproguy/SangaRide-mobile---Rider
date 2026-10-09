import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/dev/dev_screen.dart';

abstract final class DevRoutes {
  static const String dev = '/dev';

  static final List<RouteBase> all = [
    if (kDebugMode) GoRoute(path: dev, builder: (context, state) => const DevScreen()),
  ];
}
