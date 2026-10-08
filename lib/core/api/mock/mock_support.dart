import 'package:sanga_ride/core/api/mock/mock_account.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_support_content.dart';
import 'package:sanga_ride/core/api/support_endpoints.dart';

abstract final class MockSupport {
  static const int _pageSize = 10;
  static const int _maxNoteLength = 500;
  static const int _firstReference = 2041;
  static const Duration _investigatingAfter = Duration(seconds: 5);
  static const Duration _decisionAfter = Duration(seconds: 15);
  static const Duration _agentJoinsAfter = Duration(seconds: 4);
  static const Duration _greetingAfter = Duration(seconds: 1);
  static const Duration _replyAfter = Duration(seconds: 2);
  static const String _agentName = 'Amaka';

  static final List<MockRoute> routes = [
    MockRoute.get(SupportEndpoints.home, (_) => _home()),
    MockRoute.get(SupportEndpoints.articles, _articles),
    MockRoute.get(SupportEndpoints.article, _article),
    MockRoute.post(SupportEndpoints.articleFeedback, _feedback),
    MockRoute.get(SupportEndpoints.issueTypes, _issueTypes),
    MockRoute.get(SupportEndpoints.tickets, _tickets),
    MockRoute.post(SupportEndpoints.tickets, _createTicket),
    MockRoute.get(SupportEndpoints.ticket, _ticket),
    MockRoute.post(SupportEndpoints.ticketResolution, _resolve),
    MockRoute.post(SupportEndpoints.chats, _startChat),
    MockRoute.get(SupportEndpoints.chatMessages, _messages),
    MockRoute.post(SupportEndpoints.chatMessages, _sendMessage),
    MockRoute.post(SupportEndpoints.chatEnd, _endChat),
  ];

  static final DateTime _seededAt = DateTime.now();
  static final Map<String, List<int>> _votes = {};
  static final List<_Ticket> _created = [];
  static _Chat? _chat;
  static int _chatSerial = 0;
  static int _messageSerial = 0;

  static List<_Ticket> get _seeded => [
    _Ticket(
      id: 'tkt_1987',
      reference: 'SR-1987',
      typeId: 'wrong_location',
      context: 'trip',
      createdAt: _seededAt.subtract(const Duration(days: 3)),
      chosen: 'resend_pin',
      chosenAt: _seededAt.subtract(const Duration(days: 3, minutes: -2)),
    ),
    _Ticket(
      id: 'tkt_1874',
      reference: 'SR-1874',
      typeId: 'wrong_fare',
      context: 'payment',
      createdAt: _seededAt.subtract(const Duration(days: 12)),
      isClosed: true,
    ),
  ];

  static List<_Ticket> get _all => [..._created.reversed, ..._seeded];

  static Map<String, dynamic> _home() {
    return {
      'topics': MockSupportContent.topics,
      'popular': [for (final id in MockSupportContent.popularIds) _summary(_articleById(id)!)],
      'contact': MockSupportContent.contact,
    };
  }

  static Map<String, dynamic>? _articleById(String id) =>
      MockSupportContent.articles.where((article) => article['id'] == id).firstOrNull;

  static Map<String, dynamic> _summary(Map<String, dynamic> article) => {
    'id': article['id'],
    'title': article['title'],
    'summary': article['summary'],
  };

  static Object? _articles(MockRequest request) {
    final topic = request.query['topic'];
    final text = '${request.query['q'] ?? ''}'.trim().toLowerCase();
    final page = (int.tryParse('${request.query['page']}') ?? 1).clamp(1, 1000);
    final matches = [
      for (final article in MockSupportContent.articles)
        if ((topic == null || topic == '' || article['topic'] == topic) && (text.isEmpty || _matches(article, text)))
          article,
    ];
    final start = (page - 1) * _pageSize;
    return {
      'items': [for (final article in matches.skip(start).take(_pageSize)) _summary(article)],
      'page': page,
      'hasMore': start + _pageSize < matches.length,
    };
  }

  static bool _matches(Map<String, dynamic> article, String text) {
    final body = [
      for (final block in article['body'] as List)
        if ((block as Map)['type'] == 'bullets') (block['items'] as List).join(' ') else block['text'],
    ].join(' ');
    return '${article['title']} ${article['summary']} $body'.toLowerCase().contains(text);
  }

  static Object? _article(MockRequest request) {
    final article = _articleById(request.params['id']!);
    if (article == null) {
      throw const MockFailure(404, 'We couldn’t find that article.', code: 'article_not_found');
    }
    return _articleJson(article);
  }

  static Map<String, dynamic> _articleJson(Map<String, dynamic> article) {
    final votes = _votes[article['id']] ?? [0, 0];
    final seed = '${article['id']}'.length * 7;
    return {
      'id': article['id'],
      'title': article['title'],
      'body': article['body'],
      'helpfulCount': 40 + seed + votes[0],
      'notHelpfulCount': 3 + seed ~/ 5 + votes[1],
    };
  }

  static Object? _feedback(MockRequest request) {
    final article = _articleById(request.params['id']!);
    if (article == null) {
      throw const MockFailure(404, 'We couldn’t find that article.', code: 'article_not_found');
    }
    final votes = _votes.putIfAbsent('${article['id']}', () => [0, 0]);
    votes[request.body['helpful'] == true ? 0 : 1]++;
    return _articleJson(article);
  }

  static Object? _issueTypes(MockRequest request) {
    final context = '${request.query['context'] ?? 'trip'}';
    return {
      'types': [
        for (final type in MockSupportContent.issueTypes)
          if (type['context'] == context)
            {'id': type['id'], 'label': type['label'], 'hint': type['hint'], 'icon': type['icon']},
      ],
    };
  }

  static Map<String, dynamic>? _typeOf(String id, String context) {
    final types = MockSupportContent.issueTypes.where((type) => type['id'] == id);
    return types.where((type) => type['context'] == context).firstOrNull ?? types.firstOrNull;
  }

  static Object? _createTicket(MockRequest request) {
    final typeId = request.body['type'];
    final context = '${request.body['context'] ?? 'trip'}';
    if (typeId == null || _typeOf('$typeId', context) == null) {
      throw const MockFailure(422, 'Pick what happened.', code: 'type_required');
    }
    final note = request.body['note'];
    if (note != null && '$note'.length > _maxNoteLength) {
      throw const MockFailure(422, 'That note is a bit long.', code: 'note_too_long');
    }
    final ticket = _Ticket(
      id: 'tkt_${_firstReference + _created.length}',
      reference: 'SR-${_firstReference + _created.length}',
      typeId: '$typeId',
      context: context,
      createdAt: DateTime.now(),
      tripId: request.body['tripId'] as String?,
    );
    _created.add(ticket);
    return _ticketJson(ticket, DateTime.now());
  }

  static Object? _tickets(MockRequest request) {
    final page = (int.tryParse('${request.query['page']}') ?? 1).clamp(1, 1000);
    final all = _all;
    final start = (page - 1) * _pageSize;
    final now = DateTime.now();
    return {
      'items': [
        for (final ticket in all.skip(start).take(_pageSize))
          {
            'id': ticket.id,
            'reference': ticket.reference,
            'typeLabel': _typeOf(ticket.typeId, ticket.context)!['label'],
            'status': ticket.status(now),
            'createdAt': _iso(ticket.createdAt),
          },
      ],
      'page': page,
      'hasMore': start + _pageSize < all.length,
    };
  }

  static _Ticket _find(MockRequest request) {
    final ticket = _all.where((ticket) => ticket.id == request.params['id']).firstOrNull;
    if (ticket == null) throw const MockFailure(404, 'We couldn’t find that report.', code: 'ticket_not_found');
    return ticket;
  }

  static Object? _ticket(MockRequest request) => _ticketJson(_find(request), DateTime.now());

  static Object? _resolve(MockRequest request) {
    final ticket = _find(request);
    final now = DateTime.now();
    final options = ticket.options;
    final option = '${request.body['option']}';
    if (ticket.status(now) != 'action_needed' || !options.any((candidate) => candidate['id'] == option)) {
      throw const MockFailure(422, 'That option isn’t available anymore.', code: 'invalid_option');
    }
    ticket
      ..chosen = option
      ..chosenAt = now;
    return _ticketJson(ticket, now);
  }

  static Map<String, dynamic> _ticketJson(_Ticket ticket, DateTime now) {
    final status = ticket.status(now);
    return {
      'id': ticket.id,
      'reference': ticket.reference,
      'type': ticket.typeId,
      'typeLabel': _typeOf(ticket.typeId, ticket.context)!['label'],
      'status': status,
      'events': ticket.events(now),
      'resolutionOptions': status == 'action_needed' ? ticket.options : null,
      'tripId': ticket.tripId,
      'createdAt': _iso(ticket.createdAt),
      'serverTime': _iso(now),
    };
  }

  static Object? _startChat(MockRequest request) {
    final existing = _chat;
    final now = DateTime.now();
    if (existing != null && !existing.isEnded) return existing.chatJson(now);
    final chat = _Chat(
      id: 'chat_${++_chatSerial}',
      startedAt: now,
      ticketReference: _all.where((ticket) => ticket.id == request.body['ticketId']).firstOrNull?.reference,
      hasTrip: request.body['tripId'] != null,
    );
    _chat = chat;
    return chat.chatJson(now);
  }

  static _Chat _chatOf(MockRequest request) {
    final chat = _chat;
    if (chat == null || chat.id != request.params['id']) {
      throw const MockFailure(404, 'That chat isn’t available anymore.', code: 'chat_unavailable');
    }
    return chat;
  }

  static Object? _messages(MockRequest request) {
    final chat = _chatOf(request);
    final now = DateTime.now();
    chat.advance(now);
    final after = request.query['after'];
    final index = after == null ? -1 : chat.messages.indexWhere((message) => message['id'] == after);
    return {'chat': chat.chatJson(now), 'messages': chat.messages.skip(index + 1).toList(), 'serverTime': _iso(now)};
  }

  static Object? _sendMessage(MockRequest request) {
    final chat = _chatOf(request);
    final now = DateTime.now();
    if (chat.isEnded) throw const MockFailure(409, 'This chat has ended.', code: 'chat_ended');
    chat.advance(now);
    final clientId = request.body['clientId'];
    final duplicate = chat.messages.where((message) => clientId != null && message['clientId'] == clientId).firstOrNull;
    if (duplicate != null) return duplicate;
    final text = '${request.body['text']}'.trim();
    final message = chat.add('rider', text, now, clientId: clientId as String?);
    chat.scheduleReply(text, now);
    return message;
  }

  static Object? _endChat(MockRequest request) {
    final chat = _chatOf(request);
    final now = DateTime.now();
    chat.advance(now);
    chat.end(now);
    return chat.chatJson(now);
  }

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static String nextMessageId() => 'msg_${++_messageSerial}';
}

class _Ticket {
  _Ticket({
    required this.id,
    required this.reference,
    required this.typeId,
    required this.context,
    required this.createdAt,
    this.tripId,
    this.chosen,
    this.chosenAt,
    this.isClosed = false,
  });

  final String id;
  final String reference;
  final String typeId;
  final String context;
  final DateTime createdAt;
  final String? tripId;
  final bool isClosed;
  String? chosen;
  DateTime? chosenAt;

  Map<String, dynamic> get _type => MockSupport._typeOf(typeId, context)!;

  bool get _needsAction => _type['needsAction'] == true;

  List<Map<String, dynamic>> get options => [
    for (final option in (_type['options'] as List? ?? const [])) Map<String, dynamic>.from(option as Map),
  ];

  String status(DateTime now) {
    final age = now.difference(createdAt);
    if (age < MockSupport._investigatingAfter) return 'reported';
    if (age < MockSupport._decisionAfter) return 'investigating';
    if (_needsAction && chosen == null) return 'action_needed';
    return isClosed ? 'closed' : 'resolved';
  }

  List<Map<String, dynamic>> events(DateTime now) {
    final age = now.difference(createdAt);
    final decidedAt = createdAt.add(MockSupport._decisionAfter);
    return [
      _event('reported', createdAt, '${_type['reported']}'),
      if (age >= MockSupport._investigatingAfter)
        _event('investigating', createdAt.add(MockSupport._investigatingAfter), '${_type['investigating']}'),
      if (age >= MockSupport._decisionAfter && _needsAction)
        _event('action_requested', decidedAt, 'Pick what works best for you'),
      if (age >= MockSupport._decisionAfter && _needsAction && chosen != null)
        _event('action_taken', chosenAt!, 'You chose: ${_chosenLabel()}'),
      if (age >= MockSupport._decisionAfter && !_needsAction) _event('action_taken', decidedAt, '${_type['resolved']}'),
      if (age >= MockSupport._decisionAfter && (!_needsAction || chosen != null))
        _event('resolved', chosenAt ?? decidedAt, 'All sorted. Thanks for your patience.'),
    ];
  }

  String _chosenLabel() => options.where((option) => option['id'] == chosen).firstOrNull?['label'] as String? ?? '';

  Map<String, dynamic> _event(String type, DateTime at, String detail) => {
    'type': type,
    'at': MockSupport._iso(at),
    'detail': detail,
  };
}

class _Chat {
  _Chat({required this.id, required this.startedAt, required this.ticketReference, required this.hasTrip});

  final String id;
  final DateTime startedAt;
  final String? ticketReference;
  final bool hasTrip;
  final List<Map<String, dynamic>> messages = [];
  final List<(DateTime, String)> _replies = [];
  DateTime? endedAt;
  bool _hasJoined = false;
  bool _hasGreeted = false;

  bool get isEnded => endedAt != null;

  DateTime get _joinsAt => startedAt.add(MockSupport._agentJoinsAfter);

  String _status(DateTime now) => isEnded ? 'ended' : (now.isBefore(_joinsAt) ? 'queued' : 'active');

  Map<String, dynamic> chatJson(DateTime now) {
    final status = _status(now);
    final waitSeconds = _joinsAt.difference(now).inSeconds;
    return {
      'id': id,
      'status': status,
      'agent': status == 'queued' ? null : {'name': MockSupport._agentName, 'photoUrl': null},
      'queuePosition': status == 'queued' ? (waitSeconds > 2 ? 2 : 1) : 0,
    };
  }

  Map<String, dynamic> add(String role, String text, DateTime at, {String? clientId}) {
    final message = {
      'id': MockSupport.nextMessageId(),
      'clientId': clientId,
      'text': text,
      'senderRole': role,
      'createdAt': MockSupport._iso(at),
      'status': 'sent',
    };
    messages.add(message);
    return message;
  }

  void advance(DateTime now) {
    if (isEnded) return;
    if (!_hasJoined && !now.isBefore(_joinsAt)) {
      _hasJoined = true;
      add('system', '${MockSupport._agentName} joined the chat', _joinsAt);
    }
    final greetAt = _joinsAt.add(MockSupport._greetingAfter);
    if (_hasJoined && !_hasGreeted && !now.isBefore(greetAt)) {
      _hasGreeted = true;
      add('agent', _greeting(), greetAt);
    }
    final due = [
      for (final reply in _replies)
        if (!now.isBefore(reply.$1)) reply,
    ];
    for (final reply in due) {
      _replies.remove(reply);
      add('agent', reply.$2, reply.$1);
    }
  }

  void scheduleReply(String text, DateTime now) {
    final earliest = now.add(MockSupport._replyAfter);
    final greetAt = _joinsAt.add(MockSupport._greetingAfter).add(MockSupport._replyAfter);
    _replies.add((earliest.isAfter(greetAt) ? earliest : greetAt, _replyTo(text)));
  }

  void end(DateTime now) {
    if (isEnded) return;
    endedAt = now;
    add('system', 'Chat ended', now);
  }

  String _greeting() {
    final name = MockAccount.firstName;
    final reference = ticketReference;
    final context = reference != null
        ? ' I can see your report $reference.'
        : hasTrip
        ? ' I can see the trip you mentioned.'
        : '';
    return 'Hi $name, this is ${MockSupport._agentName} from Sanga support.$context How can I help?';
  }

  String _replyTo(String text) {
    final lower = text.toLowerCase();
    bool has(List<String> words) => words.any(lower.contains);
    if (has(['thank'])) return 'You’re welcome! Anything else I can help with?';
    if (has(['refund', 'charge', 'payment', 'fare', 'card', 'money', 'paid'])) {
      return 'I can see your recent payments. Can you tell me the amount and the date so I can check it?';
    }
    if (has(['package', 'parcel', 'delivery', 'recipient'])) {
      return 'Sorry about that. Which delivery is this about? Share the pickup place and the time and I’ll check it.';
    }
    if (has(['driver', 'pickup', 'late', 'trip', 'ride', 'cancel'])) {
      return 'I’m sorry about that. Which trip is this about? Share the pickup place and the time and I’ll check it.';
    }
    if (has(['verif', 'selfie', 'id card', 'document'])) {
      return 'I can see your verification status. Which step is giving you trouble?';
    }
    if (has(['account', 'profile', 'phone', 'email', 'name'])) {
      return 'Happy to help with your account. What would you like to change?';
    }
    return 'Thanks for explaining. Let me look into that for you.';
  }
}
