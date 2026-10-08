import 'package:sanga_ride/core/api/delivery_live_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_delivery.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';

class MockDeliveryClock {
  const MockDeliveryClock({
    required this.now,
    required this.status,
    required this.createdAt,
    required this.arrivedAt,
    required this.pinVerifiedAt,
    required this.arrivedDropoffAt,
    required this.completedAt,
    required this.dropoff,
  });

  final DateTime now;
  final String status;
  final DateTime createdAt;
  final DateTime arrivedAt;
  final DateTime? pinVerifiedAt;
  final DateTime? arrivedDropoffAt;
  final DateTime? completedAt;
  final Map<String, dynamic> dropoff;
}

abstract final class MockDeliveryLive {
  static final List<MockRoute> routes = [
    MockRoute.post(DeliveryLiveEndpoints.pickupConfirmation, _confirmPickup),
    MockRoute.post(DeliveryLiveEndpoints.issues, _reportIssue),
    MockRoute.get(DeliveryLiveEndpoints.issue, _issue),
    MockRoute.post(DeliveryLiveEndpoints.issueResolution, _resolveIssue),
  ];

  static const String refuseHook = '#refuse';

  static const String pickupProofAsset = 'assets/images/delivery_pickup_proof.webp';
  static const String deliveryProofAsset = 'assets/images/delivery_proof.webp';

  static const Duration _checkAfterConfirm = Duration(seconds: 5);
  static const Duration _driverWaitsForSender = Duration(seconds: 90);
  static const Duration _verifyingAfterArrival = Duration(seconds: 6);
  static const Duration _handedOverAfterArrival = Duration(seconds: 12);
  static const Duration _investigatingAfter = Duration(seconds: 5);
  static const Duration _actionNeededAfter = Duration(seconds: 15);
  static const double _proofOffsetDegrees = 0.0003;

  static const Map<String, ({String label, String weight})> _sizes = {
    'small': (label: 'Small box', weight: 'Up to 5kg'),
    'medium': (label: 'Medium box', weight: 'Up to 20kg'),
    'large': (label: 'Large box', weight: 'Up to 50kg'),
  };

  static const Map<String, String> _investigatingCopy = {
    'driver_not_moving': 'Our team is checking your driver’s status',
    'cannot_reach_driver': 'Our team is trying to reach your driver',
    'wrong_location': 'Our team is checking where your driver is',
    'extra_payment': 'Our team is reviewing the payment request',
    'unable_to_complete': 'Our team is checking if your driver can finish',
    'safety': 'Our safety team is looking at this now',
    'other': 'Our team is reviewing your report',
  };

  static const Map<String, String> _reasonLabels = {
    'driver_not_moving': 'Driver not moving',
    'cannot_reach_driver': 'Cannot reach driver',
    'wrong_location': 'Wrong location',
    'extra_payment': 'Driver asked for extra payment',
    'unable_to_complete': 'Unable to complete delivery',
    'safety': 'Safety concern',
    'other': 'Other',
  };

  static const Map<String, Map<String, String>> _options = {
    'reassign': {'label': 'Assign a new driver', 'blurb': 'A new driver will take over and finish your delivery'},
    'return_to_sender': {'label': 'Return to sender', 'blurb': 'The package will go back to the pickup location'},
    'cancel': {'label': 'Cancel delivery', 'blurb': 'The delivery will be cancelled and any refund due will be sorted'},
  };

  static const Map<String, String> _resolutionCopy = {
    'reassign': 'A new driver is taking over your delivery',
    'return_to_sender': 'Your package is going back to the pickup location',
    'cancel': 'Your delivery was cancelled',
  };

  static const String _refusalNote = 'The contents didn’t match the description';
  static const String _refusalMessage =
      'Because the package didn’t match what you described, a ₦500 fee applies. You haven’t been charged for the delivery itself.';

  static final Map<String, Map<String, dynamic>> _deliveries = {};
  static final Map<String, ({DateTime at, String? photoId})> _confirmations = {};
  static final Map<String, _MockIssue> _issues = {};
  static final Map<String, String> _openIssueByTrip = {};
  static int _issueCounter = 2040;

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static void attach(String tripId, Map<String, dynamic>? request) {
    final block = request?['delivery'];
    if (block is! Map && request?['tripType'] != 'delivery') return;
    _deliveries[tripId] = _asMap(block);
  }

  static bool isDelivery(String id) => _deliveries.containsKey(id);

  static String _itemName(String id) => _asMap(_asMap(_deliveries[id])['item'])['name'] as String? ?? 'Package';

  static bool _refuses(String id) => _itemName(id).toLowerCase().contains(refuseHook);

  static DateTime? refusedAt(String id, DateTime? pinVerifiedAt) {
    if (!isDelivery(id) || !_refuses(id) || pinVerifiedAt == null) return null;
    final confirmedAt = _confirmations[id]?.at;
    return confirmedAt != null ? confirmedAt.add(_checkAfterConfirm) : pinVerifiedAt.add(_driverWaitsForSender);
  }

  static DateTime? _pickedUpAt(String id, DateTime? pinVerifiedAt) {
    if (!isDelivery(id) || _refuses(id) || pinVerifiedAt == null) return null;
    final confirmedAt = _confirmations[id]?.at;
    return confirmedAt != null ? confirmedAt.add(_checkAfterConfirm) : pinVerifiedAt.add(_driverWaitsForSender);
  }

  static bool _isStarted(DateTime? at, DateTime now) => at != null && !at.isAfter(now);

  static String _stage(String id, MockDeliveryClock clock) {
    final now = clock.now;
    final refused = refusedAt(id, clock.pinVerifiedAt);
    if (_isStarted(refused, now)) return 'refused';
    return switch (clock.status) {
      'driver_en_route' => 'to_pickup',
      'driver_arrived' => 'at_pickup',
      'pin_verified' => _isStarted(_pickedUpAt(id, clock.pinVerifiedAt), now) ? 'picked_up' : 'inspecting',
      'in_progress' => 'to_dropoff',
      'arrived_dropoff' => _stageAtDropoff(clock),
      'completed' => 'delivered',
      _ => 'failed',
    };
  }

  static String _stageAtDropoff(MockDeliveryClock clock) {
    final arrivedAt = clock.arrivedDropoffAt;
    if (arrivedAt == null) return 'at_dropoff';
    final elapsed = clock.now.difference(arrivedAt);
    if (elapsed < _verifyingAfterArrival) return 'at_dropoff';
    return elapsed < _handedOverAfterArrival ? 'verifying_recipient' : 'delivered';
  }

  static bool canComplete(String id, MockDeliveryClock clock) => _stage(id, clock) == 'delivered';

  static DateTime? _handedOverAt(MockDeliveryClock clock) => clock.arrivedDropoffAt?.add(_handedOverAfterArrival);

  static Map<String, dynamic> _item(String id) {
    final item = _asMap(_asMap(_deliveries[id])['item']);
    final size = _sizes[item['size']] ?? _sizes['small']!;
    final photoId = item['photoId'] as String?;
    return {
      'name': item['name'] ?? 'Package',
      'description': item['description'],
      'size': item['size'] ?? 'small',
      'sizeLabel': size.label,
      'weightLabel': size.weight,
      'packageType': item['packageType'] ?? 'not_fragile',
      'photoUrl': MockDelivery.uploadUrlOf(photoId),
      'declaredValue': item['declaredValue'],
    };
  }

  static Map<String, dynamic> _recipient(String id) {
    final recipient = _asMap(_asMap(_deliveries[id])['recipient']);
    return {'name': recipient['name'] ?? 'Your recipient', 'phone': recipient['phone'] ?? ''};
  }

  static Map<String, dynamic>? tripBlock(String id, MockDeliveryClock Function() clockOf) {
    final block = _deliveries[id];
    if (block == null) return null;
    final clock = clockOf();
    final stage = _stage(id, clock);
    final pickedUpAt = _pickedUpAt(id, clock.pinVerifiedAt);
    final handedOverAt = _handedOverAt(clock);
    final confirmation = _confirmations[id];
    final refusedAt = MockDeliveryLive.refusedAt(id, clock.pinVerifiedAt);
    final hasPickedUp = _isStarted(pickedUpAt, clock.now);
    final hasHandedOver = stage == 'delivered' && _isStarted(handedOverAt, clock.now);
    return {
      'tier': block['tier'] ?? 'standard',
      'kind': block['kind'] ?? 'package',
      'item': _item(id),
      'recipient': _recipient(id),
      'stage': stage,
      'pickupProof': hasPickedUp ? {'photoUrl': pickupProofAsset, 'at': _iso(pickedUpAt!)} : null,
      'senderConfirmation': confirmation == null
          ? null
          : {'photoUrl': MockDelivery.uploadUrlOf(confirmation.photoId), 'at': _iso(confirmation.at)},
      'deliveryProof': hasHandedOver ? _deliveryProof(clock, handedOverAt!) : null,
      'refusal': stage == 'refused' && refusedAt != null
          ? {'reason': 'not_as_declared', 'note': _refusalNote, 'message': _refusalMessage, 'at': _iso(refusedAt)}
          : null,
      'events': _events(id, clock, pickedUpAt, handedOverAt),
    };
  }

  static Map<String, dynamic> _deliveryProof(MockDeliveryClock clock, DateTime handedOverAt) => {
    'photoUrl': deliveryProofAsset,
    'at': _iso(handedOverAt),
    'lat': (clock.dropoff['lat'] as num) + _proofOffsetDegrees,
    'lng': (clock.dropoff['lng'] as num) + _proofOffsetDegrees,
    'recipientConfirmed': true,
  };

  static List<Map<String, dynamic>> _events(
    String id,
    MockDeliveryClock clock,
    DateTime? pickedUpAt,
    DateTime? handedOverAt,
  ) {
    final candidates = <(String, DateTime?)>[
      ('accepted', clock.createdAt),
      ('arrived_pickup', clock.arrivedAt),
      ('picked_up', pickedUpAt),
      ('arrived_dropoff', clock.arrivedDropoffAt),
      ('handed_over', handedOverAt),
      ('delivered', clock.completedAt),
    ];
    return [
      for (final (type, at) in candidates) {'type': type, 'at': _isStarted(at, clock.now) ? _iso(at!) : null},
    ];
  }

  static Map<String, dynamic>? receiptBlock(String id, MockDeliveryClock Function() clockOf) {
    final block = _deliveries[id];
    if (block == null) return null;
    final clock = clockOf();
    final handedOverAt = _handedOverAt(clock);
    return {
      'tier': block['tier'] ?? 'standard',
      'itemName': _item(id)['name'],
      'recipientName': _recipient(id)['name'],
      'deliveredAt': handedOverAt == null ? null : _iso(handedOverAt),
      'proofPhotoUrl': deliveryProofAsset,
    };
  }

  static MockDeliveryLink? _link;

  static void bind(MockDeliveryLink link) => _link = link;

  static MockDeliveryLink _requireLink(String tripId) {
    final link = _link;
    if (link == null || !isDelivery(tripId)) {
      throw const MockFailure(404, 'We can’t find that delivery.', code: 'not_found');
    }
    return link;
  }

  static Object? _confirmPickup(MockRequest request) {
    final id = request.params['id']!;
    final link = _requireLink(id);
    final clock = link.clockOf(id);
    if (clock.status != 'pin_verified' || _stage(id, clock) == 'refused') {
      throw const MockFailure(409, 'This pickup has moved on.', code: 'wrong_stage');
    }
    _confirmations.putIfAbsent(id, () => (at: DateTime.now(), photoId: request.body['photoId'] as String?));
    return link.payloadOf(id);
  }

  static Object? _reportIssue(MockRequest request) {
    final tripId = request.params['id']!;
    final link = _requireLink(tripId);
    final reason = request.body['reason'] as String?;
    if (reason == null || !_reasonLabels.containsKey(reason)) {
      throw const MockFailure(422, 'Pick a reason first.', code: 'invalid_reason');
    }
    final status = link.clockOf(tripId).status;
    if (status == 'completed' || status == 'cancelled') {
      throw const MockFailure(409, 'This delivery has already ended.', code: 'trip_ended');
    }
    final existingId = _openIssueByTrip[tripId];
    final existing = existingId == null ? null : _issues[existingId];
    if (existing != null && existing.resolvedAt == null) return _issueJson(existing, link);
    final issue = _MockIssue(
      id: 'iss_${++_issueCounter}',
      reference: 'DL-$_issueCounter',
      tripId: tripId,
      reason: reason,
      createdAt: DateTime.now(),
    );
    _issues[issue.id] = issue;
    _openIssueByTrip[tripId] = issue.id;
    return _issueJson(issue, link);
  }

  static Object? _issue(MockRequest request) {
    final issue = _requireIssue(request);
    return _issueJson(issue, _requireLink(issue.tripId));
  }

  static Object? _resolveIssue(MockRequest request) {
    final issue = _requireIssue(request);
    final link = _requireLink(issue.tripId);
    final option = request.body['option'] as String?;
    final status = _issueStatus(issue, DateTime.now());
    final available = _optionIdsFor(_stage(issue.tripId, link.clockOf(issue.tripId)));
    if (status != 'action_needed' || option == null || !available.contains(option)) {
      throw const MockFailure(409, 'That option isn’t available anymore.', code: 'option_unavailable');
    }
    issue
      ..resolution = option
      ..resolvedAt = DateTime.now();
    switch (option) {
      case 'reassign':
        link.reassign(issue.tripId);
      case 'return_to_sender':
        link.cancel(issue.tripId, reason: 'delivery_returned');
      case 'cancel':
        link.cancel(issue.tripId, reason: 'delivery_cancelled');
    }
    return _issueJson(issue, link);
  }

  static _MockIssue _requireIssue(MockRequest request) {
    final issue = _issues[request.params['issueId']];
    if (issue == null || issue.tripId != request.params['id']) {
      throw const MockFailure(404, 'We can’t find that report.', code: 'not_found');
    }
    return issue;
  }

  static String _issueStatus(_MockIssue issue, DateTime now) {
    if (issue.resolvedAt != null) return 'resolved';
    final elapsed = now.difference(issue.createdAt);
    if (elapsed < _investigatingAfter) return 'reported';
    return elapsed < _actionNeededAfter ? 'investigating' : 'action_needed';
  }

  static List<String> _optionIdsFor(String stage) {
    final hasPickedUp = const {'picked_up', 'to_dropoff', 'at_dropoff', 'verifying_recipient'}.contains(stage);
    return [if (hasPickedUp || stage == 'inspecting') 'reassign', if (hasPickedUp) 'return_to_sender', 'cancel'];
  }

  static Map<String, dynamic> _issueJson(_MockIssue issue, MockDeliveryLink link) {
    final now = DateTime.now();
    final status = _issueStatus(issue, now);
    final investigatingAt = issue.createdAt.add(_investigatingAfter);
    final actionAt = issue.createdAt.add(_actionNeededAfter);
    final resolution = issue.resolution;
    return {
      'id': issue.id,
      'reference': issue.reference,
      'status': status,
      'events': [
        {'type': 'reported', 'at': _iso(issue.createdAt), 'detail': _reasonLabels[issue.reason]},
        {
          'type': 'investigating',
          'at': now.isBefore(investigatingAt) ? null : _iso(investigatingAt),
          'detail': _investigatingCopy[issue.reason],
        },
        {
          'type': 'action_taken',
          'at': now.isBefore(actionAt) ? null : _iso(actionAt),
          'detail': 'We found some ways forward. Pick what suits you best.',
        },
        {
          'type': 'resolved',
          'at': issue.resolvedAt == null ? null : _iso(issue.resolvedAt!),
          'detail': resolution == null ? 'Pick an option to wrap this up' : _resolutionCopy[resolution],
        },
      ],
      'resolutionOptions': status == 'action_needed'
          ? [
              for (final optionId in _optionIdsFor(_stage(issue.tripId, link.clockOf(issue.tripId))))
                {'id': optionId, ..._options[optionId]!},
            ]
          : null,
      'serverTime': _iso(now),
    };
  }
}

class _MockIssue {
  _MockIssue({
    required this.id,
    required this.reference,
    required this.tripId,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String reference;
  final String tripId;
  final String reason;
  final DateTime createdAt;
  String? resolution;
  DateTime? resolvedAt;
}

class MockDeliveryLink {
  const MockDeliveryLink({
    required this.clockOf,
    required this.payloadOf,
    required this.cancel,
    required this.reassign,
  });

  final MockDeliveryClock Function(String id) clockOf;
  final Map<String, dynamic> Function(String id) payloadOf;
  final void Function(String id, {required String reason}) cancel;
  final void Function(String id) reassign;
}
