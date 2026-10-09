import 'package:go_router/go_router.dart';
import 'package:sanga_ride/model/history/history_tab.dart';
import 'package:sanga_ride/view/history/history_actions_screen.dart';
import 'package:sanga_ride/view/history/history_detail_screen.dart';
import 'package:sanga_ride/view/history/history_screen.dart';

abstract final class HistoryRoutes {
  static const String history = '/rides/history';
  static const String detail = '/rides/history/:id';
  static const String actions = '/rides/history/:id/actions';

  static const String _tabKey = 'tab';

  static String detailOf(String id) => detail.replaceFirst(':id', id);

  static String actionsOf(String id) => actions.replaceFirst(':id', id);

  static final List<RouteBase> all = [
    GoRoute(
      path: history,
      builder: (context, state) => HistoryScreen(
        initialTab: HistoryTab.values.asNameMap()[state.uri.queryParameters[_tabKey]] ?? HistoryTab.completed,
      ),
    ),
    GoRoute(
      path: detail,
      builder: (context, state) => HistoryDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: actions,
      builder: (context, state) => HistoryActionsScreen(id: state.pathParameters['id']!),
    ),
  ];
}
