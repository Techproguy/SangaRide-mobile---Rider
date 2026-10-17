import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class SupportEndpoints {
  static const String _support = '/support';

  static const String home = '$_support/home';
  static const String articles = '$_support/articles';
  static const String article = '$_support/articles/:id';
  static const String articleFeedback = '$_support/articles/:id/feedback';
  static const String issueCategories = '/issues/categories';
  static const String issues = '/issues';
  static const String ticket = '/issues/:id';
  static const String ticketResolution = '/issues/:id/resolution';
  static const String chats = '$_support/chats';
  static const String chatMessages = '$_support/chats/:id/messages';
  static const String chatEnd = '$_support/chats/:id/end';

  static String of(String template, String id) => fillPath(template, {'id': id});
}
