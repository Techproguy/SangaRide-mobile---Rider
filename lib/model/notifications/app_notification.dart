enum NotificationRoute {
  trip('trip'),
  scheduledRide('scheduled_ride'),
  wallet('wallet'),
  supportTicket('support_ticket'),
  verification('verification'),
  none('none');

  const NotificationRoute(this.code);

  final String code;

  static NotificationRoute fromCode(Object? code) => values.where((route) => route.code == '$code').firstOrNull ?? none;
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

  static NotificationKind fromCode(Object? code) => values.where((kind) => kind.code == '$code').firstOrNull ?? general;
}

class NotificationAction {
  const NotificationAction({required this.route, this.id});

  factory NotificationAction.fromJson(Map<String, dynamic>? json) =>
      NotificationAction(route: NotificationRoute.fromCode(json?['route']), id: json?['id'] as String?);

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

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    kind: NotificationKind.fromCode(json['kind']),
    title: json['title'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse('${json['createdAt']}').toLocal(),
    readAt: json['readAt'] == null ? null : DateTime.parse('${json['readAt']}').toLocal(),
    action: NotificationAction.fromJson(
      json['action'] == null ? null : Map<String, dynamic>.from(json['action'] as Map),
    ),
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

  factory NotificationsPage.fromJson(Map<String, dynamic> json) => NotificationsPage(
    items: [for (final item in json['items'] as List) AppNotification.fromJson(Map<String, dynamic>.from(item as Map))],
    unreadCount: (json['unreadCount'] as num).toInt(),
    hasMore: json['hasMore'] == true,
  );

  final List<AppNotification> items;
  final int unreadCount;
  final bool hasMore;
}
