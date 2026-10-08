import 'package:go_router/go_router.dart';
import 'package:sanga_ride/view/notifications/notifications_screen.dart';

abstract final class NotificationRoutes {
  static const String list = '/notifications';

  static final List<RouteBase> all = [GoRoute(path: list, builder: (context, state) => const NotificationsScreen())];
}
