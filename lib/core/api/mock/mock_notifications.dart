import 'package:sanga_ride/core/api/mock/mock_groups.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_verification.dart';
import 'package:sanga_ride/core/api/notification_endpoints.dart';

abstract final class MockNotifications {
  static const int _pageSize = 10;
  static const int _unreadSeeded = 4;

  static final List<MockRoute> routes = [
    MockRoute.get(NotificationEndpoints.list, _list),
    MockRoute.post(NotificationEndpoints.read, _read),
    MockRoute.post(NotificationEndpoints.readAll, _readAll),
  ];

  static final DateTime _seededAt = DateTime.now();

  static const List<_Spec> _specs = [
    _Spec(
      'ride',
      'Driver has arrived at pick up spot',
      'Chinedu is outside in a white Toyota Corolla.',
      6,
      'trip',
      'hist_01',
    ),
    _Spec(
      'ride',
      'Scheduled ride for 6:00pm',
      'Your driver is booked. We’ll remind you before pickup.',
      35,
      'scheduled_ride',
      'sched_1',
    ),
    _Spec(
      'delivery',
      'Delivery complete, make payment',
      'Your package has been handed over. Settle up to wrap it up.',
      70,
      'trip',
      'hist_02',
    ),
    _Spec(
      'support',
      'Your report is resolved',
      'SR-1987 is sorted. Tap to see how it ended.',
      140,
      'support_ticket',
      'tkt_1987',
    ),
    _Spec('message', 'Driver sent you a message', 'Ngozi says: I’m at the gate, the blue one.', 260, 'trip', 'hist_03'),
    _Spec('payment', 'Wallet topped up', 'Your top up is in your Sanga wallet and ready to use.', 420, 'wallet', null),
    _Spec(
      'general',
      'Ride a little, save a lot',
      'Try Saver pricing next time you book and keep more in your pocket.',
      700,
      'none',
      null,
    ),
    _Spec(
      'safety',
      'Add someone you trust',
      'Set up emergency contacts in Safety Centre so help is one tap away.',
      1000,
      'none',
      null,
    ),
    _Spec(
      'ride',
      'Scheduled ride reminder',
      'Your ride is coming up in two days. Change it any time before pickup.',
      1500,
      'scheduled_ride',
      'sched_2',
    ),
    _Spec('delivery', 'Delivery on its way', 'Your driver has picked up your package.', 2200, 'trip', 'hist_05'),
    _Spec(
      'support',
      'Report closed',
      'SR-1874 is closed. Thanks for your patience.',
      3000,
      'support_ticket',
      'tkt_1874',
    ),
    _Spec('general', 'We updated our terms', 'Have a quick read of the new rider terms.', 4200, 'none', null),
    _Spec(
      'payment',
      'Receipt for your last trip',
      'Your trip receipt is ready to view and share.',
      5600,
      'trip',
      'hist_06',
    ),
    _Spec('ride', 'How was your ride?', 'Rate your trip and help us keep rides great.', 7000, 'trip', 'hist_07'),
    _Spec(
      'general',
      'Welcome to Sanga',
      'You’re all set. Book your first ride whenever you’re ready.',
      12000,
      'none',
      null,
    ),
  ];

  static final Set<String> _readIds = {for (var index = _unreadSeeded; index < _specs.length; index++) _id(index)};

  static List<Map<String, dynamic>> _all() => [
    ?_approvalJson(),
    ?_verificationJson(),
    for (var index = 0; index < _specs.length; index++) _json(index),
  ];

  static Object? _list(MockRequest request) {
    final page = (int.tryParse('${request.query['page']}') ?? 1).clamp(1, 1000);
    final start = (page - 1) * _pageSize;
    final all = _all();
    return {
      'items': all.skip(start).take(_pageSize).toList(),
      'unreadCount': all.where((item) => item['readAt'] == null).length,
      'hasMore': start + _pageSize < all.length,
      'page': page,
      'serverTime': _iso(DateTime.now()),
    };
  }

  static Object? _read(MockRequest request) {
    final id = request.params['id']!;
    final all = _all();
    if (!all.any((item) => item['id'] == id)) {
      throw const MockFailure(404, 'We couldn’t find that notification.', code: 'notification_not_found');
    }
    _readIds.add(id);
    return {'unreadCount': _all().where((item) => item['readAt'] == null).length};
  }

  static Object? _readAll(MockRequest request) {
    _readIds.addAll([for (final item in _all()) item['id'] as String]);
    return {'unreadCount': 0};
  }

  static String _id(int index) => 'ntf_${(index + 1).toString().padLeft(2, '0')}';

  static Map<String, dynamic>? _approvalJson() {
    final notice = MockGroups.pendingApprovalNotice();
    if (notice == null) return null;
    final at = notice['at'] as DateTime;
    final id = 'ntf_approval_${notice['groupId']}';
    return {
      'id': id,
      'kind': 'ride',
      'title': '${(notice['memberName'] as String).split(' ').first} needs your OK',
      'body': 'A ride that goes past their limit is waiting for you to approve or decline.',
      'createdAt': _iso(at),
      'readAt': _readIds.contains(id) ? _iso(at.add(const Duration(seconds: 30))) : null,
      'action': {'route': 'group_approvals', 'id': notice['groupId']},
    };
  }

  static Map<String, dynamic>? _verificationJson() {
    final outcome = MockVerification.outcome;
    if (outcome == null) return null;
    final id = 'ntf_verification_${outcome.at.millisecondsSinceEpoch}';
    return {
      'id': id,
      'kind': 'verification',
      'title': outcome.isVerified ? 'You’re verified' : 'We couldn’t verify your ID',
      'body': outcome.isVerified
          ? 'Thanks for waiting. Your account is verified.'
          : 'Your ID photo wasn’t clear. Open the Verification centre to try again.',
      'createdAt': _iso(outcome.at),
      'readAt': _readIds.contains(id) ? _iso(outcome.at.add(const Duration(seconds: 30))) : null,
      'action': {'route': 'verification', 'id': null},
    };
  }

  static Map<String, dynamic> _json(int index) {
    final spec = _specs[index];
    final createdAt = _seededAt.subtract(Duration(minutes: spec.minutesAgo));
    final id = _id(index);
    return {
      'id': id,
      'kind': spec.kind,
      'title': spec.title,
      'body': spec.body,
      'createdAt': _iso(createdAt),
      'readAt': _readIds.contains(id) ? _iso(createdAt.add(const Duration(minutes: 1))) : null,
      'action': {'route': spec.route, 'id': spec.routeId},
    };
  }

  static String _iso(DateTime time) => time.toUtc().toIso8601String();
}

class _Spec {
  const _Spec(this.kind, this.title, this.body, this.minutesAgo, this.route, this.routeId);

  final String kind;
  final String title;
  final String body;
  final int minutesAgo;
  final String route;
  final String? routeId;
}
