import 'dart:math' as math;

import 'package:sanga_ride/core/api/mock/mock_card_tokenizer.dart';
import 'package:sanga_ride/core/api/history_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_groups.dart';
import 'package:sanga_ride/core/api/mock/mock_history.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/wallet_endpoints.dart';

abstract final class MockWallet {
  static final List<MockRoute> routes = [
    MockRoute.get(WalletEndpoints.wallet, _overview),
    MockRoute.get(WalletEndpoints.transactions, _transactions),
    MockRoute.get(WalletEndpoints.transaction, _transaction),
    MockRoute.post(WalletEndpoints.topUps, _createTopUp),
    MockRoute.get(WalletEndpoints.topUp, _topUp),
    MockRoute.post(WalletEndpoints.topUpAuthorize, _authorize),
    MockRoute.get(WalletEndpoints.groupWallet, _overview),
    MockRoute.get(WalletEndpoints.groupTransactions, _transactions),
    MockRoute.get(WalletEndpoints.groupTransaction, _transaction),
    MockRoute.post(WalletEndpoints.groupTopUps, _createTopUp),
    MockRoute.get(WalletEndpoints.groupTopUp, _topUp),
    MockRoute.post(WalletEndpoints.groupTopUpAuthorize, _authorize),
  ];

  static const int _openingBalance = 140580;
  static const int _minTopUp = 500;
  static const int _maxTopUp = 500000;
  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 50;
  static const Duration _transferSettlesAfter = Duration(seconds: 6);
  static const Duration _transferWindow = Duration(minutes: 30);
  static const String _declinedLast4 = '0002';
  static const String _brokeLast4 = '9995';
  static const String _otpMessage = 'Enter the 4 digit code your bank just sent you.';

  static const Map<String, dynamic> _virtualAccount = {
    'bankName': 'Sanga Wallet (Wema)',
    'accountNumber': '8123456789',
    'accountName': 'Sanga / Ada Okafor',
  };

  static const List<(int, int, int, String, bool)> _seedTopUps = [
    (1, 9, 20000, 'card', true),
    (3, 18, 5000, 'transfer', true),
    (5, 8, 10000, 'card', true),
    (7, 14, 15000, 'transfer', true),
    (9, 20, 25000, 'transfer', true),
    (11, 12, 15000, 'card', true),
    (14, 7, 30000, 'card', true),
    (16, 19, 10000, 'card', false),
    (17, 19, 10000, 'transfer', true),
    (19, 10, 20000, 'transfer', true),
    (21, 16, 5000, 'card', true),
    (23, 9, 15000, 'transfer', true),
    (25, 11, 20000, 'card', true),
    (27, 17, 10000, 'card', true),
    (29, 8, 50000, 'transfer', true),
  ];

  static const List<(String, int, int, int, String, String?)> _seedCredits = [
    ('adjustment', 29, 8, 1000, 'Welcome bonus', null),
    ('adjustment', 12, 13, 500, 'Promo credit', null),
    ('adjustment', 6, 15, 500, 'Referral bonus', null),
    ('refund', 20, 10, 300, 'Cancellation fee refunded', 'hist_16'),
    ('refund', 8, 11, 300, 'Cancellation fee refunded', 'hist_28'),
  ];

  static final DateTime _anchor = DateTime.now();
  static final _Book _personal = _Book(balance: _openingBalance, virtualAccount: _virtualAccount, ledger: _seed());
  static final Map<String, _Book> _groupBooks = {};
  static final List<Map<String, dynamic>> _cards = [
    {'id': 'card_1', 'brand': 'visa', 'last4': '4242', 'expiry': '08/28'},
  ];
  static int _sequence = 0;

  static const Map<String, int> _groupOpening = {'grp_johnsons': 96400, 'grp_ray': 250000};

  static const Map<String, List<(String, String, int, int, int, String?)>> _groupSeeds = {
    'grp_johnsons': [
      ('top_up', 'Top up by transfer', 50000, 2, 9, null),
      ('ride_payment', 'Ride for Tomi', -6500, 1, 15, 'hist_00'),
      ('ride_payment', 'Ride for Tife', -4400, 2, 17, 'hist_02'),
      ('top_up', 'Top up with card', 20000, 4, 11, null),
      ('ride_payment', 'Ride for Tomi', -5800, 5, 8, 'hist_06'),
      ('ride_payment', 'Ride for Chidi', -7200, 6, 19, 'hist_08'),
      ('top_up', 'Top up by transfer', 30000, 9, 10, null),
      ('ride_payment', 'Ride for Tife', -3900, 11, 14, 'hist_10'),
    ],
    'grp_ray': [
      ('top_up', 'Top up by transfer', 200000, 3, 9, null),
      ('ride_payment', 'Ride for Georgina', -6500, 1, 9, 'hist_01'),
      ('ride_payment', 'Ride for Ada', -8200, 2, 18, 'hist_03'),
      ('ride_payment', 'Ride for Funke', -5200, 3, 8, 'hist_05'),
      ('top_up', 'Top up with card', 100000, 7, 12, null),
      ('ride_payment', 'Ride for Georgina', -9100, 8, 17, 'hist_07'),
    ],
  };

  static _Book _openGroupBook(String groupId) {
    final seeds = _groupSeeds[groupId] ?? const [];
    final book = _Book(
      balance: _groupOpening[groupId] ?? 0,
      virtualAccount: {
        'bankName': 'Sanga Wallet (Wema)',
        'accountNumber': '${9100000000 + groupId.hashCode.abs() % 90000000}',
        'accountName': 'Sanga / ${MockGroups.nameOf(groupId)}',
      },
      ledger: [],
    );
    for (final (index, seed) in seeds.indexed) {
      final isTopUp = seed.$1 == 'top_up';
      book.ledger.add(
        _Entry(
          id: 'wtx_${groupId}_${index.toString().padLeft(2, '0')}',
          kind: seed.$1,
          title: seed.$2,
          amount: seed.$3,
          status: 'completed',
          createdAt: _daysAgo(seed.$4, seed.$5),
          reference: _reference(isTopUp ? 'SR-TU' : 'SR-PAY', index + 21 + groupId.length),
          meta: isTopUp
              ? {
                  'method': seed.$2.contains('card') ? 'card' : 'transfer',
                  if (seed.$2.contains('card')) ...{'cardBrand': 'visa', 'cardLast4': '4242'},
                }
              : {
                  'tripId': seed.$6,
                  'route': 'Chicken Republic to The Palms Mall',
                  'fare': -seed.$3,
                  'paymentMethod': 'group_wallet',
                },
        ),
      );
    }
    return book;
  }

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static String _nextId(String prefix) => '${prefix}_${(++_sequence).toString().padLeft(4, '0')}';

  static DateTime _daysAgo(int days, int hour) =>
      DateTime(_anchor.year, _anchor.month, _anchor.day, hour, (days * 7) % 60).subtract(Duration(days: days));

  static String _reference(String prefix, int seed) => '$prefix-${(48200000 + seed * 7919) % 100000000}';

  static List<_Entry> _seed() {
    final entries = [..._seedTopUpEntries(), ..._seedRideEntries(), ..._seedCreditEntries()];
    return entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<_Entry> _seedTopUpEntries() => [
    for (final (index, seed) in _seedTopUps.indexed)
      _Entry(
        id: 'wtx_topup_${index.toString().padLeft(2, '0')}',
        kind: 'top_up',
        title: seed.$4 == 'card' ? 'Top up with card' : 'Top up by transfer',
        amount: seed.$3,
        status: seed.$5 ? 'completed' : 'failed',
        createdAt: _daysAgo(seed.$1, seed.$2),
        reference: _reference('SR-TU', index + 3),
        meta: {
          'method': seed.$4,
          if (seed.$4 == 'card') ...{'cardBrand': 'visa', 'cardLast4': '4242'},
          if (!seed.$5) 'failureReason': 'Your bank declined this card.',
        },
      ),
  ];

  static List<_Entry> _seedRideEntries() {
    final trips = _completedTrips();
    return [
      for (final trip in trips)
        if (MockHistory.isPaidWithWallet(trip['id'] as String)) _rideEntry(trip),
    ];
  }

  static List<Map<String, dynamic>> _completedTrips() {
    final route = MockHistory.routes.firstWhere((route) => route.match('GET', HistoryEndpoints.rides) != null);
    final page = route.handler(
      MockRequest(
        path: HistoryEndpoints.rides,
        body: {},
        query: {'status': 'completed', 'page': 1, 'pageSize': 50},
        params: {},
      ),
    );
    return [for (final item in (page as Map)['items'] as List) Map<String, dynamic>.from(item as Map)];
  }

  static _Entry _rideEntry(Map<String, dynamic> trip) {
    final id = trip['id'] as String;
    final pickup = (trip['pickup'] as Map)['name'] as String;
    final dropoff = (trip['dropoff'] as Map)['name'] as String;
    final isDelivery = trip['kind'] == 'delivery';
    final fare = (trip['fare'] as num).toInt();
    return _Entry(
      id: 'wtx_ride_$id',
      kind: 'ride_payment',
      title: isDelivery ? 'Delivery: ${trip['itemName']}' : 'Ride to $dropoff',
      amount: -fare,
      status: 'completed',
      createdAt: DateTime.parse(trip['occurredAt'] as String).add(const Duration(minutes: 1)),
      reference: _reference('SR-PAY', int.parse(id.substring(5))),
      meta: {
        'tripId': id,
        'route': '$pickup to $dropoff',
        'fare': fare,
        'paymentMethod': 'wallet',
        'tripKind': isDelivery ? 'delivery' : 'ride',
      },
    );
  }

  static List<_Entry> _seedCreditEntries() => [
    for (final (index, seed) in _seedCredits.indexed)
      _Entry(
        id: 'wtx_${seed.$1}_${index.toString().padLeft(2, '0')}',
        kind: seed.$1,
        title: seed.$5,
        amount: seed.$4,
        status: 'completed',
        createdAt: _daysAgo(seed.$2, seed.$3),
        reference: _reference(seed.$1 == 'refund' ? 'SR-RF' : 'SR-AD', index + 11),
        meta: {'note': seed.$5, 'tripId': ?seed.$6},
      ),
  ];

  static _Book _bookOf(MockRequest request) {
    final groupId = request.params['groupId'];
    if (groupId == null) return _personal;
    final book = _groupBooks[groupId] ?? _openGroupBook(groupId);
    _groupBooks[groupId] = book;
    return book;
  }

  static void _requireTopUpAccess(MockRequest request) {
    final groupId = request.params['groupId'];
    if (groupId != null && !MockGroups.canTopUp(groupId)) {
      throw const MockFailure(403, 'Only admins can add money to the group wallet.', code: 'not_allowed');
    }
  }

  static void _syncTopUps(_Book book) {
    for (final topUp in book.topUps.values) {
      topUp.sync(DateTime.now());
    }
  }

  static Object? _overview(MockRequest request) {
    final book = _bookOf(request);
    _syncTopUps(book);
    return {
      'balance': book.balance,
      'currency': 'NGN',
      'limits': {'minTopUp': _minTopUp, 'maxTopUp': _maxTopUp},
      'virtualAccount': book.virtualAccount,
      'savedCards': [for (final card in _cards) Map<String, dynamic>.of(card)],
      'serverTime': _iso(DateTime.now()),
    };
  }

  static Object? _transactions(MockRequest request) {
    final book = _bookOf(request);
    _syncTopUps(book);
    final kinds = ('${request.query['kind'] ?? ''}').split(',').where((kind) => kind.isNotEmpty).toSet();
    final page = math.max(1, int.tryParse('${request.query['page'] ?? 1}') ?? 1);
    final limit = (int.tryParse('${request.query['limit'] ?? _defaultPageSize}') ?? _defaultPageSize).clamp(
      1,
      _maxPageSize,
    );
    final matching = [
      for (final entry in _sortedLedger(book))
        if (kinds.isEmpty || kinds.contains(entry.kind)) entry,
    ];
    final start = (page - 1) * limit;
    final end = math.min(start + limit, matching.length);
    return {
      'transactions': start >= matching.length
          ? const []
          : [for (final entry in matching.sublist(start, end)) entry.toJson()],
      'page': page,
      'hasMore': end < matching.length,
      'serverTime': _iso(DateTime.now()),
    };
  }

  static List<_Entry> _sortedLedger(_Book book) => [...book.ledger]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static Object? _transaction(MockRequest request) {
    final book = _bookOf(request);
    _syncTopUps(book);
    final entry = book.ledger.where((entry) => entry.id == request.params['id']).firstOrNull;
    if (entry == null) throw const MockFailure(404, 'We can’t find that transaction.', code: 'transaction_not_found');
    return {...entry.toJson(), 'serverTime': _iso(DateTime.now())};
  }

  static void _checkAmount(int? amount) {
    if (amount == null || amount < _minTopUp || amount > _maxTopUp) {
      throw const MockFailure(
        422,
        'That amount is outside what you can add.',
        code: 'amount_out_of_range',
        data: {'min': _minTopUp, 'max': _maxTopUp},
      );
    }
  }

  static Object? _createTopUp(MockRequest request) {
    _requireTopUpAccess(request);
    final book = _bookOf(request);
    final amount = (request.body['amount'] as num?)?.toInt();
    _checkAmount(amount);
    return switch (request.body['method']) {
      'card' => _createCardTopUp(book, amount!, request.body),
      'transfer' => _createTransferTopUp(book, amount!),
      _ => throw const MockFailure(422, 'Pick a way to add money.', code: 'invalid_method'),
    };
  }

  static MockCardRef _cardOf(Map<String, dynamic> body) {
    final cardId = body['cardId'] as String?;
    if (cardId != null) {
      final card = _cards.where((card) => card['id'] == cardId).firstOrNull;
      if (card == null) throw const MockFailure(404, 'We can’t find that card.', code: 'card_not_found');
      return MockCardRef(
        brand: card['brand'] as String,
        last4: card['last4'] as String,
        expiry: card['expiry'] as String,
      );
    }
    final token = (body['card'] as Map?)?['token'] as String?;
    return MockCardTokenizer.decode(token) ??
        (throw const MockFailure(422, 'Check your card details.', code: 'invalid_card'));
  }

  static Object? _createCardTopUp(_Book book, int amount, Map<String, dynamic> body) {
    final card = _cardOf(body);
    if (card.last4 == _declinedLast4) _decline(book, amount, card, 'card_declined', 'Your bank declined this card.');
    if (card.last4 == _brokeLast4) {
      _decline(book, amount, card, 'insufficient_funds', 'That card doesn’t have enough money for this top up.');
    }
    final isSaved = body['cardId'] != null;
    final topUp = _TopUp(
      book: book,
      id: _nextId('tu'),
      method: 'card',
      amount: amount,
      createdAt: DateTime.now(),
      card: card,
      shouldSaveCard: !isSaved && body['saveCard'] == true,
    );
    book.topUps[topUp.id] = topUp;
    if (isSaved) {
      topUp.complete();
      return topUp.toJson();
    }
    topUp.status = 'requires_action';
    return topUp.toJson(withAmount: false);
  }

  static Never _decline(_Book book, int amount, MockCardRef card, String code, String message) {
    book.ledger.add(
      _Entry(
        id: _nextId('wtx_topup_failed'),
        kind: 'top_up',
        title: 'Top up with card',
        amount: amount,
        status: 'failed',
        createdAt: DateTime.now(),
        reference: _reference('SR-TU', _sequence + 40),
        meta: {'method': 'card', 'cardBrand': card.brand, 'cardLast4': card.last4, 'failureReason': message},
      ),
    );
    throw MockFailure(402, message, code: code);
  }

  static Object? _createTransferTopUp(_Book book, int amount) {
    final now = DateTime.now();
    final topUp = _TopUp(
      book: book,
      id: _nextId('tu'),
      method: 'transfer',
      amount: amount,
      createdAt: now,
      expiresAt: now.add(_transferWindow),
    );
    book.topUps[topUp.id] = topUp;
    topUp.entry = _Entry(
      id: _nextId('wtx_topup'),
      kind: 'top_up',
      title: 'Top up by transfer',
      amount: amount,
      status: 'pending',
      createdAt: now,
      reference: _reference('SR-TU', _sequence + 60),
      meta: {'method': 'transfer', 'topUpId': topUp.id, 'expiresAt': _iso(topUp.expiresAt!)},
    );
    book.ledger.add(topUp.entry!);
    return {'id': topUp.id, 'status': 'awaiting_transfer', 'expiresAt': _iso(topUp.expiresAt!)};
  }

  static _TopUp _topUpOf(MockRequest request) {
    final topUp = _bookOf(request).topUps[request.params['id']];
    if (topUp == null) throw const MockFailure(404, 'We can’t find that top up.', code: 'top_up_not_found');
    topUp.sync(DateTime.now());
    return topUp;
  }

  static Object? _topUp(MockRequest request) => _topUpOf(request).toJson();

  static Object? _authorize(MockRequest request) {
    _requireTopUpAccess(request);
    final topUp = _topUpOf(request);
    if (topUp.status != 'requires_action') return topUp.toJson();
    if (request.body['otp'] != MockData.otpCode) {
      throw const MockFailure(422, 'That code didn’t match. Check it and try again.', code: 'otp_mismatch');
    }
    topUp.complete();
    return topUp.toJson();
  }

  static int get balance {
    _syncTopUps(_personal);
    return _personal.balance;
  }

  static int groupBalance(String groupId) {
    final book = _groupBooks[groupId] ?? _openGroupBook(groupId);
    _groupBooks[groupId] = book;
    _syncTopUps(book);
    return book.balance;
  }

  static int groupMonthSpent(String groupId) {
    final book = _groupBooks[groupId] ?? _openGroupBook(groupId);
    _groupBooks[groupId] = book;
    final now = DateTime.now();
    return book.ledger
        .where(
          (entry) =>
              entry.kind == 'ride_payment' && entry.createdAt.year == now.year && entry.createdAt.month == now.month,
        )
        .fold(0, (total, entry) => total - entry.amount);
  }

  static void payTrip({
    required String tripId,
    required int fare,
    required String pickup,
    required String dropoff,
    required DateTime at,
    String? itemName,
    String? groupId,
    String? memberName,
  }) {
    final book = groupId == null ? _personal : (_groupBooks[groupId] ?? _openGroupBook(groupId));
    if (groupId != null) _groupBooks[groupId] = book;
    _syncTopUps(book);
    if (book.balance < fare) {
      throw MockFailure(
        402,
        groupId == null
            ? 'There isn’t enough in your wallet for this ride.'
            : 'The group wallet is short for this ride.',
        code: groupId == null ? 'insufficient_balance' : 'group_wallet_short',
        data: {'balance': book.balance, 'shortBy': fare - book.balance},
      );
    }
    book.balance -= fare;
    book.ledger.add(
      _Entry(
        id: 'wtx_ride_$tripId',
        kind: 'ride_payment',
        title: switch ((itemName, memberName)) {
          (final item?, _) => 'Delivery: $item',
          (null, final member?) => 'Ride for $member',
          (null, null) => 'Ride to $dropoff',
        },
        amount: -fare,
        status: 'completed',
        createdAt: at,
        reference: _reference('SR-PAY', _sequence++ + 70),
        meta: {
          'tripId': tripId,
          'route': '$pickup to $dropoff',
          'fare': fare,
          'paymentMethod': groupId == null ? 'wallet' : 'group_wallet',
          'tripKind': itemName == null ? 'ride' : 'delivery',
        },
      ),
    );
  }

  static void _saveCard(MockCardRef card) {
    final exists = _cards.any((saved) => saved['last4'] == card.last4 && saved['brand'] == card.brand);
    if (exists) return;
    _cards.add({'id': _nextId('card'), 'brand': card.brand, 'last4': card.last4, 'expiry': card.expiry});
  }
}

class _Entry {
  _Entry({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.reference,
    required this.meta,
  });

  final String id;
  final String kind;
  final String title;
  final int amount;
  final DateTime createdAt;
  final String reference;
  final Map<String, dynamic> meta;
  String status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'title': title,
    'amount': amount,
    'status': status,
    'createdAt': MockWallet._iso(createdAt),
    'reference': reference,
    'meta': meta,
  };
}

class _Book {
  _Book({required this.balance, required this.virtualAccount, required this.ledger});

  final Map<String, dynamic> virtualAccount;
  final List<_Entry> ledger;
  final Map<String, _TopUp> topUps = {};
  int balance;
}

class _TopUp {
  _TopUp({
    required this.book,
    required this.id,
    required this.method,
    required this.amount,
    required this.createdAt,
    this.expiresAt,
    this.card,
    this.shouldSaveCard = false,
  });

  final _Book book;
  final String id;
  final String method;
  final int amount;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final MockCardRef? card;
  final bool shouldSaveCard;
  String status = 'awaiting_transfer';
  _Entry? entry;

  bool get _neverArrives => amount % 10 == 7;

  void sync(DateTime now) {
    if (method != 'transfer' || status != 'awaiting_transfer') return;
    if (!_neverArrives && now.difference(createdAt) >= MockWallet._transferSettlesAfter) {
      complete();
    } else if (now.isAfter(expiresAt!)) {
      status = 'expired';
      entry
        ?..status = 'failed'
        ..meta['failureReason'] = 'We didn’t receive your transfer in time.';
    }
  }

  void complete() {
    status = 'completed';
    book.balance += amount;
    final existing = entry;
    if (existing != null) {
      existing.status = 'completed';
      return;
    }
    final paidWith = card!;
    entry = _Entry(
      id: MockWallet._nextId('wtx_topup'),
      kind: 'top_up',
      title: 'Top up with card',
      amount: amount,
      status: 'completed',
      createdAt: DateTime.now(),
      reference: MockWallet._reference('SR-TU', MockWallet._sequence + 90),
      meta: {'method': 'card', 'cardBrand': paidWith.brand, 'cardLast4': paidWith.last4, 'topUpId': id},
    );
    book.ledger.add(entry!);
    if (shouldSaveCard) MockWallet._saveCard(paidWith);
  }

  Map<String, dynamic> toJson({bool withAmount = true}) => {
    'id': id,
    'status': status,
    'method': method,
    if (withAmount) 'amount': amount,
    if (expiresAt != null) 'expiresAt': MockWallet._iso(expiresAt!),
    'action': status == 'requires_action' ? {'type': 'otp', 'message': MockWallet._otpMessage} : null,
    'serverTime': MockWallet._iso(DateTime.now()),
  };
}
