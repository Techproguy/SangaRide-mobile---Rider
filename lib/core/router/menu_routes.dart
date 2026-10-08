import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/menu/menu_screen.dart';

abstract final class MenuRoutes {
  static const String menu = '/menu';

  static final List<RouteBase> all = [GoRoute(path: menu, builder: (context, state) => const MenuScreen())];
}
