import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/boot/boot_screen.dart';

abstract final class BootRoutes {
  static const String boot = '/boot';

  static final List<RouteBase> all = [GoRoute(path: boot, builder: (context, state) => const BootScreen())];
}
