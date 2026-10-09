import 'package:sanga_ride_core/sanga_ride_core.dart';

enum NotificationRoute {
  trip('trip'),
  scheduledRide('scheduled_ride'),
  wallet('wallet'),
  supportTicket('support_ticket'),
  verification('verification'),
  groupApprovals('group_approvals'),
  none('none');

  const NotificationRoute(this.code);

  final String code;

  static NotificationRoute fromCode(Object? code) =>
      enumByCode(values, '$code', (route) => route.code, NotificationRoute.none);
}

enum NotificationKind {
  message('message'),
  payment('payment'),
  ride('ride'),
  delivery('delivery'),
  support('support'),
  verification('verification'),
  safety('safety'),
  general('general');

  const NotificationKind(this.code);

  final String code;

  static NotificationKind fromCode(Object? code) =>
      enumByCode(values, '$code', (kind) => kind.code, NotificationKind.general);
}

class NotificationAction {
  const NotificationAction({required this.route, this.id});

  factory NotificationAction.fromReader(JsonReader? reader) =>
      NotificationAction(route: NotificationRoute.fromCode(reader?.strOrNull('route')), id: reader?.strOrNull('id'));

  final NotificationRoute route;
  final String? id;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.readAt,
    required this.action,
  });

  factory AppNotification.fromReader(JsonReader reader) => AppNotification(
    id: reader.str('id'),
    kind: NotificationKind.fromCode(reader.strOrNull('kind')),
    title: reader.strOr('title', ''),
    body: reader.strOr('body', ''),
    createdAt: reader.time('createdAt').toLocal(),
    readAt: reader.timeOrNull('readAt')?.toLocal(),
    action: NotificationAction.fromReader(reader.objectOrNull('action')),
  );

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final NotificationAction action;

  bool get isRead => readAt != null;

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    readAt: readAt ?? at,
    action: action,
  );
}

class NotificationsPage {
  const NotificationsPage({required this.items, required this.unreadCount, required this.hasMore});

  factory NotificationsPage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final items = reader.listOf('items', AppNotification.fromReader);
    return NotificationsPage(
      items: items,
      unreadCount: reader.intOr('unreadCount', items.where((item) => !item.isRead).length),
      hasMore: reader.boolOr('hasMore', false),
    );
  }

  final List<AppNotification> items;
  final int unreadCount;
  final bool hasMore;
}
