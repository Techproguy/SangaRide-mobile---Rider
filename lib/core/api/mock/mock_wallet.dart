import 'dart:math' as math;

import 'package:sanga_ride/core/api/mock/mock_groups.dart';
import 'package:sanga_ride/core/api/mock/mock_history.dart';
import 'package:sanga_ride/core/api/mock/mock_money.dart';
import 'package:sanga_ride/core/api/mock/mock_region.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/wallet_endpoints.dart';

abstract final class MockWallet {
  static final List<MockRoute> routes = [
    MockRoute.get(WalletEndpoints.wallet, _overview),
    MockRoute.get(WalletEndpoints.transactions, _transactions),
    MockRoute.get(WalletEndpoints.transaction, _transaction),
    MockRoute.post(WalletEndpoints.topUpCreate, _createTopUp),
    MockRoute.get(WalletEndpoints.topUps, _findTopUps),
    MockRoute.get(WalletEndpoints.topUp, _topUp),
    MockRoute.get(WalletEndpoints.groupWallet, _overview),
    MockRoute.get(WalletEndpoints.groupTransactions, _transactions),
    MockRoute.get(WalletEndpoints.groupTransaction, _transaction),
    MockRoute.post(WalletEndpoints.groupTopUpCreate, _createTopUp),
    MockRoute.get(WalletEndpoints.groupTopUps, _findTopUps),
    MockRoute.get(WalletEndpoints.groupTopUp, _topUp),
  ];

  static const int _openingBalance = 140580;
  static const int _minTopUp = 500;
  static const int _maxTopUp = 500000;
  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 50;
  static const Duration _settlesAfter = Duration(seconds: 6);
  static const Duration _expiryWindow = Duration(minutes: 30);
  static const int _recentCount = 5;
  static const String _topUpInstructions =
      'Transfer to the account shown, then your wallet is credited automatically once the payment is confirmed.';

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
  static final _Book _personal = _Book(balance: _openingBalance, ledger: _seed());
  static final Map<String, _Book> _groupBooks = {};
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
    final book = _Book(balance: _groupOpening[groupId] ?? 0, ledger: []);
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
                  'route': '${MockRegion.spec('mock_cr_ikeja').name} to ${MockRegion.spec('mock_palms').name}',
                  'fare': -seed.$3,
                  'paymentMethod': 'group_wallet',
                },
        ),
      );
    }
    return book;
  }

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static num _naira(num amount) => MockMoney.of(amount).major;

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

  static List<Map<String, dynamic>> _completedTrips() => MockHistory.summaries('completed');

  static _Entry _rideEntry(Map<String, dynamic> trip) {
    final id = trip['id'] as String;
    final pickup = (trip['pickup'] as Map)['name'] as String;
    final dropoff = (trip['dropoff'] as Map)['name'] as String;
    final isDelivery = trip['kind'] == 'delivery';
    final fare = MockMoney.naira(trip['fare']).toInt();
    return _Entry(
      id: 'wtx_ride_$id',
      kind: 'ride_payment',
      title: isDelivery ? 'Delivery: ${trip['itemName']}' : 'Ride to $dropoff',
      amount: -fare,
      status: 'completed',
      createdAt: DateTime.parse(trip['occurredAt'] as String).add(const Duration(minutes: 1)),
      reference: _reference('SR-PAY', int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? id.hashCode.abs()),
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
      'balance': _naira(book.balance),
      'currency': MockMoney.currency,
      'ownerType': request.params['groupId'] == null ? 'user' : 'group',
      'recentTransactions': [for (final entry in _sortedLedger(book).take(_recentCount)) entry.toJson()],
    };
  }

  static Object? _findTopUps(MockRequest request) {
    final book = _bookOf(request);
    _syncTopUps(book);
    final key = request.query['idempotencyKey'];
    final matching = [
      for (final topUp in book.topUps.values)
        if (key == null || topUp.intentKey == key) topUp,
    ];
    return {
      'topUps': [for (final topUp in matching) topUp.toItemJson()],
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
    };
  }

  static List<_Entry> _sortedLedger(_Book book) => [...book.ledger]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static Object? _transaction(MockRequest request) {
    final book = _bookOf(request);
    _syncTopUps(book);
    final entry = book.ledger.where((entry) => entry.id == request.params['id']).firstOrNull;
    if (entry == null) throw const MockFailure(404, 'We can’t find that transaction.', code: 'transaction_not_found');
    return entry.toJson();
  }

  static void _checkAmount(int? amount) {
    if (amount == null || amount < _minTopUp || amount > _maxTopUp) {
      throw MockFailure(
        422,
        'That amount is outside what you can add.',
        code: 'amount_out_of_range',
        data: {'min': _naira(_minTopUp), 'max': _naira(_maxTopUp)},
      );
    }
  }

  static Object? _createTopUp(MockRequest request) {
    _requireTopUpAccess(request);
    final book = _bookOf(request);
    final amount = MockMoney.nairaOrNull(request.body['amount'])?.toInt();
    _checkAmount(amount);
    final now = DateTime.now();
    final topUp = _TopUp(
      book: book,
      id: _nextId('tu'),
      reference: 'WTP-${959804759 + _sequence * 7919}',
      amount: amount!,
      createdAt: now,
      expiresAt: now.add(_expiryWindow),
      intentKey: request.headers['Idempotency-Key'] as String?,
    );
    book.topUps[topUp.id] = topUp;
    book.ledger.add(topUp.entry);
    return topUp.toCreationJson();
  }

  static _TopUp _topUpOf(MockRequest request) {
    final topUp = _bookOf(request).topUps[request.params['id']];
    if (topUp == null) throw const MockFailure(404, 'We can’t find that top up.', code: 'top_up_not_found');
    topUp.sync(DateTime.now());
    return topUp;
  }

  static Object? _topUp(MockRequest request) => _topUpOf(request).toItemJson();

  static List<Map<String, dynamic>> pendingTopUps() {
    final books = {'personal': _personal, for (final entry in _groupBooks.entries) 'group:${entry.key}': entry.value};
    return [
      for (final entry in books.entries)
        for (final topUp in entry.value.topUps.values)
          if (_syncedStatus(topUp) case final status when _pendingStatuses.contains(status))
            {
              'id': topUp.id,
              'scope': entry.key == 'personal' ? 'personal' : 'group',
              if (entry.key != 'personal') 'groupId': entry.key.substring('group:'.length),
              'status': status,
            },
    ];
  }

  static const Set<String> _pendingStatuses = {'pending'};

  static String _syncedStatus(_TopUp topUp) {
    topUp.sync(DateTime.now());
    return topUp.status;
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
        data: {'balance': MockMoney.json(book.balance), 'shortBy': MockMoney.json(fare - book.balance)},
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
    'type': kind == 'top_up' ? 'topup' : kind,
    'direction': amount < 0 ? 'debit' : 'credit',
    'description': title,
    'amount': MockWallet._naira(amount.abs()),
    'rideId': meta['tripId'],
    'status': status,
    'createdAt': MockWallet._iso(createdAt),
    'reference': reference,
    'meta': {...meta, if (meta['fare'] != null) 'fare': MockWallet._naira(meta['fare'] as num)},
  };
}

class _Book {
  _Book({required this.balance, required this.ledger});

  final List<_Entry> ledger;
  final Map<String, _TopUp> topUps = {};
  int balance;
}

class _TopUp {
  _TopUp({
    required this.book,
    required this.id,
    required this.reference,
    required this.amount,
    required this.createdAt,
    required this.expiresAt,
    this.intentKey,
  }) : entry = _Entry(
         id: MockWallet._nextId('wtx_topup'),
         kind: 'top_up',
         title: 'Top up with card',
         amount: amount,
         status: 'pending',
         createdAt: createdAt,
         reference: reference,
         meta: {'method': 'card', 'topUpId': id, 'expiresAt': MockWallet._iso(expiresAt)},
       );

  final _Book book;
  final String id;
  final String reference;
  final int amount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? intentKey;
  final _Entry entry;
  String status = 'pending';

  bool get _neverArrives => MockMoney.of(amount).wholeMajor % 10 == 7;

  void sync(DateTime now) {
    if (status != 'pending') return;
    if (!_neverArrives && now.difference(createdAt) >= MockWallet._settlesAfter) {
      complete();
    } else if (now.isAfter(expiresAt)) {
      status = 'expired';
      entry
        ..status = 'failed'
        ..meta['failureReason'] = 'We didn’t receive your transfer in time.';
    }
  }

  void complete() {
    status = 'completed';
    book.balance += amount;
    entry.status = 'completed';
  }

  Map<String, dynamic> toCreationJson() => {
    'id': id,
    'reference': reference,
    'amount': MockWallet._naira(amount),
    'status': status,
    'currency': MockMoney.currency,
    'instructions': MockWallet._topUpInstructions,
  };

  Map<String, dynamic> toItemJson() => {
    'id': id,
    'status': status,
    'method': 'card',
    'amount': MockWallet._naira(amount),
    'reference': reference,
    'createdAt': MockWallet._iso(createdAt),
  };
}
