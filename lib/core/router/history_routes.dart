import 'package:go_router/go_router.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/model/history/history_tab.dart';
import 'package:sanga_ride/view/history/history_actions_screen.dart';
import 'package:sanga_ride/view/history/history_detail_screen.dart';
import 'package:sanga_ride/view/history/history_screen.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class HistoryRoutes {
  static const String history = '/rides/history';
  static const String detail = '/rides/history/:id';
  static const String actions = '/rides/history/:id/actions';

  static const String _tabKey = 'tab';
  static const String _kindKey = 'kind';

  static String detailOf(String id, {HistoryKind? kind}) {
    final path = fillPath(detail, {'id': id});
    return kind == null ? path : '$path?$_kindKey=${kind.code}';
  }

  static String actionsOf(String id) => fillPath(actions, {'id': id});

  static final List<RouteBase> all = [
    GoRoute(
      path: history,
      builder: (context, state) => HistoryScreen(
        initialTab: HistoryTab.values.asNameMap()[state.uri.queryParameters[_tabKey]] ?? HistoryTab.completed,
      ),
    ),
    GoRoute(
      path: detail,
      builder: (context, state) => HistoryDetailScreen(
        id: state.pathParameters['id']!,
        kind: HistoryKind.fromCode(state.uri.queryParameters[_kindKey]),
      ),
    ),
    GoRoute(
      path: actions,
      builder: (context, state) => HistoryActionsScreen(id: state.pathParameters['id']!),
    ),
  ];
}
