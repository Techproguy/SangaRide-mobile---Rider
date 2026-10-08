abstract final class NotificationEndpoints {
  static const String _notifications = '/notifications';

  static const String list = _notifications;
  static const String read = '$_notifications/:id/read';
  static const String readAll = '$_notifications/read-all';

  static String readOf(String id) => read.replaceFirst(':id', id);
}
