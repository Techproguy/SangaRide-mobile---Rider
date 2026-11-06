import 'dart:math' as math;

import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_money.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_trip.dart';
import 'package:sanga_ride/core/api/mock/mock_trip_state.dart';
import 'package:sanga_ride/model/trip/trip_cancellation.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class MockTripChanges {
  static final List<MockRoute> routes = [
    MockRoute.post(AppEndpoints.liveTripStopsQuote, _quote),
    MockRoute.post(AppEndpoints.liveTripStops, _addStops),
    MockRoute.get(AppEndpoints.liveTripCancellation, _cancellation),
  ];

  static const int _maxStops = 3;
  static const int _stopFee = 500;
  static const int _cancelFee = 800;
  static const int _feeStep = 50;
  static const int _baseFare = 500;
  static const int _boost = 500;
  static const double _declineAboveKm = 14;
  static const double _sameSpotMeters = 50;
  static const Duration _quoteWindow = Duration(minutes: 2);
  static const Duration _freeCancelWindow = Duration(minutes: 2);
  static const List<String> _changeableStatuses = ['driver_en_route', 'driver_arrived', 'in_progress'];
  static const List<String> _driverFaultReasons = ['driver_asked', 'vehicle_mismatch', 'safety_concern'];
  static const Map<String, String> _reasonLabels = {
    'driver_late': 'Driver is taking too long',
    'driver_asked': 'Driver asked me to cancel',
    'vehicle_mismatch': 'Driver or vehicle doesn’t match',
    'no_longer_needed': 'I no longer need this ride',
    'safety_concern': 'Safety concern',
    'other': 'Other',
  };
  static const Map<String, String> _policyRules = {
    'free_window': 'WITHIN_GRACE',
    'driver_fault': 'DRIVER_FAULT',
    'driver_on_the_way': 'DRIVER_EN_ROUTE',
    'driver_arrived': 'DRIVER_ARRIVED',
    'trip_started': 'TRIP_STARTED',
  };

  static final Map<String, _StopQuote> _quotes = {};
  static int _quoteCount = 0;

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static void _requireChangeable(String id) {
    if (MockTrip.isCancelled(id) || !_changeableStatuses.contains(MockTrip.statusOf(id))) {
      throw const MockFailure(409, 'Your ride has moved on, so it can’t be changed.', code: 'trip_not_changeable');
    }
  }

  static void _requireCancellable(String id) {
    if (MockTrip.isCancelled(id)) {
      throw MockFailure(
        409,
        'This ride was already cancelled.',
        code: 'already_cancelled',
        data: {'cancelledBy': MockTrip.cancelledBy(id)},
      );
    }
    if (!_changeableStatuses.contains(MockTrip.statusOf(id))) {
      throw const MockFailure(409, 'Your ride has already moved on.', code: 'trip_not_cancellable');
    }
  }

  static List<Map<String, dynamic>> _addedStops(MockRequest request) {
    final raw = request.body['stops'];
    if (raw is! List || raw.isEmpty) throw const MockFailure(422, 'Pick a stop first.', code: 'invalid_stops');
    return [for (final stop in raw) MockTrip.placeOf(stop)];
  }

  static void _checkStopLimits(Map<String, dynamic> trip, List<Map<String, dynamic>> added) {
    final existing = (trip['stops'] as List).cast<Map<String, dynamic>>();
    if (existing.length + added.length > _maxStops) {
      throw const MockFailure(422, 'You can add up to 3 stops.', code: 'too_many_stops');
    }
    final taken = [trip['pickup'] as Map<String, dynamic>, ...existing, trip['dropoff'] as Map<String, dynamic>];
    for (final (index, stop) in added.indexed) {
      final others = [...taken, ...added.take(index)];
      if (others.any((other) => MockTrip.distanceBetween(other, stop) * 1000 < _sameSpotMeters)) {
        throw const MockFailure(422, 'That place is already on your trip.', code: 'duplicate_stop');
      }
    }
  }

  static double _pathKm(List<Map<String, dynamic>> points) {
    var km = 0.0;
    for (var i = 1; i < points.length; i++) {
      km += MockTrip.distanceBetween(points[i - 1], points[i]);
    }
    return km;
  }

  static double _extraKm(String id, List<Map<String, dynamic>> added) {
    final trip = MockTrip.stored(id);
    final start = MockTrip.routeStart(id);
    final pending = MockTrip.pendingStops(id);
    final dropoff = trip['dropoff'] as Map<String, dynamic>;
    final before = _pathKm([start, ...pending, dropoff]);
    final after = _pathKm([start, ...pending, ...added, dropoff]);
    return (after - before) * MockTrip.routeDetour;
  }

  static int _roundedToStep(num amount) => (amount / _feeStep).round() * _feeStep;

  static Object? _quote(MockRequest request) {
    final id = request.params['id']!;
    final trip = MockTrip.stored(id);
    _requireChangeable(id);
    final added = _addedStops(request);
    _checkStopLimits(trip, added);
    final fare = (trip['fare'] as num).toInt();
    final distanceKm = (trip['distanceKm'] as num).toDouble();
    final extraKm = _extraKm(id, added);
    final rate = (fare / math.max(distanceKm, 1)).clamp(60, 400);
    final stopFee = _stopFee * added.length;
    final total = fare + _roundedToStep(extraKm * rate) + stopFee;
    final base = math.min(_baseFare, fare ~/ 3);
    final boost = math.min(_boost, fare ~/ 3);
    final now = DateTime.now();
    final quoteId = 'quote_${++_quoteCount}';
    _quotes[quoteId] = _StopQuote(
      tripId: id,
      stops: added,
      total: total,
      extraKm: extraKm,
      expiresAt: now.add(_quoteWindow),
    );
    return {
      'quoteId': quoteId,
      'expiresAt': _iso(now.add(_quoteWindow)),
      'serverTime': _iso(now),
      'lines': [
        {'key': 'base_fare', 'label': 'Base fare', 'amount': MockMoney.json(base)},
        {
          'key': 'distance',
          'label': 'Distance (${SangaDistance.fromKilometers(distanceKm + extraKm)})',
          'amount': MockMoney.json(total - base - boost - stopFee),
        },
        {'key': 'boost', 'label': 'Boost', 'amount': MockMoney.json(boost)},
        {'key': 'added_stops', 'label': 'Added stop (${added.length})', 'amount': MockMoney.json(stopFee)},
      ],
      'total': MockMoney.json(total),
      'currentTotal': MockMoney.json(fare),
    };
  }

  static Object? _addStops(MockRequest request) {
    final id = request.params['id']!;
    final trip = MockTrip.stored(id);
    _requireChangeable(id);
    final quote = _quotes[request.body['quoteId']];
    final added = _addedStops(request);
    if (quote == null || quote.tripId != id || quote.stops.length != added.length) {
      throw const MockFailure(410, 'The price changed, so we need to check it again.', code: 'quote_expired');
    }
    if (!DateTime.now().isBefore(quote.expiresAt)) {
      _quotes.remove(request.body['quoteId']);
      throw const MockFailure(410, 'The price changed, so we need to check it again.', code: 'quote_expired');
    }
    _checkStopLimits(trip, quote.stops);
    if (quote.extraKm > _declineAboveKm) {
      throw const MockFailure(409, 'Your driver can’t add that stop right now.', code: 'stop_declined');
    }
    _quotes.remove(request.body['quoteId']);
    MockTrip.addStops(id, quote.stops);
    trip['fare'] = quote.total;
    trip['distanceKm'] = double.parse(((trip['distanceKm'] as num) + quote.extraKm).toStringAsFixed(1));
    return MockTrip.ridePayload(id);
  }

  static String _reasonOf(MockRequest request) {
    final reason = request.query['reasonCode'] ?? request.body['reasonCode'];
    if (reason is! String || !_reasonLabels.containsKey(reason)) {
      throw const MockFailure(422, 'Pick a reason first.', code: 'invalid_reason');
    }
    return reason;
  }

  static bool _isDriverFault(String id, String reason) {
    if (_driverFaultReasons.contains(reason)) return true;
    if (reason != 'driver_late') return false;
    final etaMinutes = (MockTrip.stored(id)['etaMinutes'] as num?) ?? 0;
    return DateTime.now().isAfter(MockTrip.createdAt(id).add(Duration(minutes: etaMinutes.round())));
  }

  static ({int fee, String feeReason}) _fee(String id, String reason) {
    final trip = MockTrip.stored(id);
    final status = MockTrip.statusOf(id);
    final sinceAccepted = DateTime.now().difference(MockTrip.createdAt(id));
    if (sinceAccepted < _freeCancelWindow) return (fee: 0, feeReason: 'free_window');
    if (_isDriverFault(id, reason)) return (fee: 0, feeReason: 'driver_fault');
    if (status == 'in_progress') {
      final fare = (trip['fare'] as num).toInt();
      final distanceKm = (trip['distanceKm'] as num).toDouble();
      final travelled = distanceKm * MockTrip.travelledFraction(id);
      final fee = _roundedToStep(travelled * fare / math.max(distanceKm, 1));
      return (fee: fee.clamp(_cancelFee, math.max(_cancelFee, fare)), feeReason: 'trip_started');
    }
    return (fee: _cancelFee, feeReason: status == 'driver_arrived' ? 'driver_arrived' : 'driver_on_the_way');
  }

  static String _noticeOf(({int fee, String feeReason}) fee) =>
      fee.fee == 0 ? 'Free cancellation' : CancelFeeReason.fromCode(fee.feeReason).notice(MockMoney.label(fee.fee));

  static Map<String, dynamic> _preview(String id, String reason, String note) {
    final ride = MockTrip.ridePayload(id);
    final fee = _fee(id, reason);
    final method = MockTripState.paymentMethod[id] ?? 'cash';
    final isRefundable = MockTripState.paidAt.containsKey(id) && method == 'card';
    final fare = (MockTrip.stored(id)['fare'] as num).toInt();
    final refund = isRefundable ? math.max(0, fare - fee.fee) : 0;
    return {
      'rideId': id,
      'reference': ride['ref'],
      'status': ride['status'],
      'kind': ride['kind'],
      'driver': ride['driver'],
      'vehicle': (ride['driver'] as Map<String, dynamic>)['vehicle'],
      'pickup': ride['pickup'],
      'dropoff': ride['dropoff'],
      'fee': {
        'amount': MockMoney.of(fee.fee).major,
        'isFree': fee.fee == 0,
        'display': fee.fee == 0 ? 'Free' : MockMoney.label(fee.fee),
        'notice': _noticeOf(fee),
        'policyRule': _policyRules[fee.feeReason],
      },
      'paymentMethod': {'type': method, 'label': '${method[0].toUpperCase()}${method.substring(1)}'},
      'refund': {'applicable': refund > 0, 'amount': MockMoney.of(refund).major, 'display': MockMoney.label(refund)},
      'reason': {'code': reason, 'label': _reasonLabels[reason], 'otherReason': note.isEmpty ? null : note},
      'confirmButtonLabel': fee.fee == 0 ? 'Cancel ride' : 'Cancel and pay ${MockMoney.label(fee.fee)}',
      'confirmDialog': {
        'message': 'Are you sure you want to cancel this ride?',
        'confirmLabel': 'Yes, cancel',
        'dismissLabel': 'Keep my ride',
      },
    };
  }

  static Object? _cancellation(MockRequest request) {
    final id = request.params['id']!;
    MockTrip.stored(id);
    _requireCancellable(id);
    return _preview(id, _reasonOf(request), '');
  }

  static Object? cancel(MockRequest request) {
    final id = request.params['id']!;
    MockTrip.stored(id);
    _requireCancellable(id);
    final reason = _reasonOf(request);
    final note = (request.body['reason'] as String?)?.trim() ?? '';
    if (reason == 'other' && note.isEmpty) {
      throw const MockFailure(422, 'Add a short note so we know what happened.', code: 'note_required');
    }
    final fee = _fee(id, reason).fee;
    MockTrip.cancel(id, reason: 'rider_cancelled', by: 'rider');
    return MockTrip.cancelledPayload(id, fee: fee);
  }
}

class _StopQuote {
  const _StopQuote({
    required this.tripId,
    required this.stops,
    required this.total,
    required this.extraKm,
    required this.expiresAt,
  });

  final String tripId;
  final List<Map<String, dynamic>> stops;
  final int total;
  final double extraKm;
  final DateTime expiresAt;
}
