import 'package:go_router/go_router.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/support_article_screen.dart';
import 'package:sanga_ride/view/support/support_articles_screen.dart';
import 'package:sanga_ride/view/support/support_chat_screen.dart';
import 'package:sanga_ride/view/support/support_contact_screen.dart';
import 'package:sanga_ride/view/support/support_home_screen.dart';
import 'package:sanga_ride/view/support/support_report_screen.dart';
import 'package:sanga_ride/view/support/support_ticket_screen.dart';
import 'package:sanga_ride/view/support/support_tickets_screen.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class SupportRoutes {
  static const String home = '/support';
  static const String articles = '/support/articles';
  static const String article = '/support/articles/:id';
  static const String contact = '/support/contact';
  static const String report = '/support/report';
  static const String tickets = '/support/tickets';
  static const String ticket = '/support/tickets/:id';
  static const String chat = '/support/chat';

  static const String _topicKey = 'topic';
  static const String _searchKey = 'search';
  static const String _contextKey = 'context';
  static const String _tripKey = 'tripId';
  static const String _ticketKey = 'ticketId';

  static String articlesOf({String? topic, bool focusSearch = false}) =>
      _withQuery(articles, {_topicKey: topic, _searchKey: focusSearch ? '1' : null});

  static String articleOf(String id) => fillPath(article, {'id': id});

  static String reportOf({IssueContext? context, String? tripId}) =>
      _withQuery(report, {_contextKey: context?.code, _tripKey: tripId});

  static String ticketOf(String id) => fillPath(ticket, {'id': id});

  static String chatOf({String? ticketId, String? tripId}) =>
      _withQuery(chat, {_ticketKey: ticketId, _tripKey: tripId});

  static String _withQuery(String path, Map<String, String?> query) {
    final present = {for (final MapEntry(:key, :value) in query.entries) key: ?value};
    return present.isEmpty ? path : Uri(path: path, queryParameters: present).toString();
  }

  static final List<RouteBase> all = [
    GoRoute(path: home, builder: (context, state) => const SupportHomeScreen()),
    GoRoute(
      path: articles,
      builder: (context, state) => SupportArticlesScreen(
        topic: state.uri.queryParameters[_topicKey],
        focusSearch: state.uri.queryParameters[_searchKey] == '1',
      ),
    ),
    GoRoute(
      path: article,
      builder: (context, state) => SupportArticleScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: contact, builder: (context, state) => const SupportContactScreen()),
    GoRoute(
      path: report,
      builder: (context, state) => SupportReportScreen(
        issueContext: IssueContext.fromCode(state.uri.queryParameters[_contextKey]),
        tripId: state.uri.queryParameters[_tripKey],
      ),
    ),
    GoRoute(path: tickets, builder: (context, state) => const SupportTicketsScreen()),
    GoRoute(
      path: ticket,
      builder: (context, state) => SupportTicketScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: chat,
      builder: (context, state) => SupportChatScreen(
        ticketId: state.uri.queryParameters[_ticketKey],
        tripId: state.uri.queryParameters[_tripKey],
      ),
    ),
  ];
}
