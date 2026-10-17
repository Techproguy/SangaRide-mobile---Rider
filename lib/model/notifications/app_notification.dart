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
      codedEnum(values, (route) => route.code, code, orElse: NotificationRoute.none);
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
      codedEnum(values, (kind) => kind.code, code, orElse: NotificationKind.general);

  static NotificationKind fromType(String? type) => switch (type?.split('.').first) {
    'wallet' => payment,
    'chat' => message,
    final family => fromCode(family),
  };
}

class NotificationAction {
  const NotificationAction({required this.route, this.id});

  factory NotificationAction.fromReader(JsonReader? reader) =>
      NotificationAction(route: NotificationRoute.fromCode(reader?.strOrNull('route')), id: reader?.strOrNull('id'));

  factory NotificationAction.fromData(NotificationKind kind, JsonReader? data) {
    final rideId = data?.strOrNull('rideId') ?? data?.strOrNull('deliveryId');
    if (rideId != null) return NotificationAction(route: NotificationRoute.trip, id: rideId);
    final ticketId = data?.strOrNull('ticketId');
    if (ticketId != null) return NotificationAction(route: NotificationRoute.supportTicket, id: ticketId);
    return NotificationAction(
      route: switch (kind) {
        NotificationKind.payment => NotificationRoute.wallet,
        NotificationKind.verification => NotificationRoute.verification,
        _ => NotificationRoute.none,
      },
    );
  }

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

  factory AppNotification.fromReader(JsonReader reader) {
    final kindCode = reader.strOrNull('kind');
    final kind = kindCode == null
        ? NotificationKind.fromType(reader.strOrNull('type'))
        : NotificationKind.fromCode(kindCode);
    final createdAt = reader.time('createdAt').toLocal();
    final action = reader.objectOrNull('action');
    return AppNotification(
      id: reader.str('id'),
      kind: kind,
      title: reader.strOr('title', ''),
      body: reader.strOr('body', ''),
      createdAt: createdAt,
      readAt: reader.timeOrNull('readAt')?.toLocal() ?? (reader.boolOr('read', false) ? createdAt : null),
      action: action == null
          ? NotificationAction.fromData(kind, reader.objectOrNull('data'))
          : NotificationAction.fromReader(action),
    );
  }

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

  factory NotificationsPage.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? meta}) {
    final reader = JsonReader(json);
    final items = reader.listOf('notifications', AppNotification.fromReader);
    return NotificationsPage(
      items: items,
      unreadCount: reader.intOr('unreadCount', items.where((item) => !item.isRead).length),
      hasMore: JsonReader(meta ?? json).boolOr('hasMore', false),
    );
  }

  final List<AppNotification> items;
  final int unreadCount;
  final bool hasMore;
}
