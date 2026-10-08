import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart' show Options;
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/mock/mock_endpoints.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';

class TripPaymentController extends GetxController {
  static const Duration pollInterval = Duration(milliseconds: 1500);
  static const String genericFailure = 'We couldn’t reach the server. Give it another go.';

  static final Options _noAutoRetry = Options(extra: {'retries': 3});

  final _api = Get.find<ApiService>();

  final Rx<PaymentState> _state = Rx<PaymentState>(const PaymentLoading());
  Timer? _poller;
  String? _tripId;
  int _epoch = 0;
  bool _isPolling = false;

  Rx<PaymentState> get stateRx => _state;

  PaymentState get state => _state.value;

  TripPayment? get payment => switch (state) {
    PaymentLoaded(:final payment) => payment,
    _ => null,
  };

  bool get isProcessing => state is PaymentProcessing;

  @override
  void onClose() {
    _invalidate();
    super.onClose();
  }

  int _invalidate() {
    _poller?.cancel();
    _poller = null;
    _isPolling = false;
    return ++_epoch;
  }

  Future<void> open(String tripId) async {
    _tripId = tripId;
    await _load();
  }

  Future<void> reload() async {
    if (_tripId == null || state is PaymentLoading) return;
    await _load();
  }

  Future<void> _load() async {
    final id = _tripId;
    if (id == null) return;
    final epoch = _invalidate();
    _state.value = const PaymentLoading();
    try {
      final response = await _api.get(MockEndpoints.tripPaymentOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      _apply(TripPayment.fromJson(_dataOf(response.data)), epoch);
    } catch (e) {
      log('payment load failed: $e');
      if (epoch == _epoch) _state.value = const PaymentUnavailable();
    }
  }

  void _apply(TripPayment payment, int epoch) {
    switch (payment.status) {
      case PaymentStatus.succeeded:
        _stopPolling();
        _state.value = PaymentPaid(payment);
      case PaymentStatus.awaitingDriver:
        _state.value = PaymentAwaitingDriver(payment);
        _startPolling(epoch);
      case PaymentStatus.declined:
        _stopPolling();
        _state.value = PaymentDeclined(payment, reason: payment.declineReason ?? PaymentDeclineReason.unknown);
      case PaymentStatus.failed:
        _stopPolling();
        _state.value = PaymentFailed(payment, method: payment.method ?? PaymentMethod.cash);
      case PaymentStatus.pending:
        _stopPolling();
        final method = payment.preferredMethod;
        _state.value = method == null ? const PaymentUnavailable() : PaymentChoosing(payment, selected: method);
    }
  }

  void select(PaymentMethod method) {
    final current = state;
    if (current is! PaymentChoosing || !current.payment.allowedMethods.contains(method)) return;
    _state.value = current.withSelected(method);
  }

  void beginCard() {
    final current = state;
    if (current is PaymentChoosing) _state.value = PaymentCardEntry(current.payment);
  }

  void backToChoosing() {
    final current = state;
    final payment = current is PaymentLoaded ? current.payment : null;
    if (payment == null || current is PaymentProcessing || current is PaymentAwaitingDriver || current is PaymentPaid) {
      return;
    }
    final method = current is PaymentChoosing ? current.selected : payment.preferredMethod;
    if (method != null) _state.value = PaymentChoosing(payment, selected: method);
  }

  void chooseCashInstead() {
    final current = state;
    if (current is! PaymentLoaded || current is PaymentProcessing || current is PaymentPaid) return;
    if (!current.payment.allowedMethods.contains(PaymentMethod.cash)) return;
    _state.value = PaymentChoosing(current.payment, selected: PaymentMethod.cash);
  }

  void retryCard() {
    final current = state;
    if (current is PaymentDeclined || current is PaymentFailed) {
      _state.value = PaymentCardEntry((current as PaymentLoaded).payment);
    }
  }

  Future<void> payCash() async {
    final current = state;
    if (current is! PaymentChoosing || current.selected != PaymentMethod.cash) return;
    await _submit(current.payment, const PaymentRequest.cash());
  }

  Future<void> payCard(CardDetails details) async {
    final current = state;
    if (current is! PaymentCardEntry) return;
    await _submit(current.payment, PaymentRequest.card(details));
  }

  Future<void> _submit(TripPayment payment, PaymentRequest request) async {
    final id = _tripId;
    if (id == null) return;
    final epoch = _invalidate();
    _state.value = PaymentProcessing(payment, method: request.method);
    try {
      final response = await _api.post(
        MockEndpoints.tripPaymentOf(id),
        data: request.toJson(),
        options: _noAutoRetry,
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return;
      _apply(TripPayment.fromJson(_dataOf(response.data)), epoch);
    } catch (e) {
      log('payment submit failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch == _epoch) _failSubmit(e, payment, request.method, id);
    }
  }

  void _failSubmit(Object error, TripPayment payment, PaymentMethod method, String id) {
    if (error is ApiException && error.code == 'already_paid') {
      unawaited(_load());
      return;
    }
    if (error is ApiException && error.statusCode == 402) {
      _state.value = PaymentDeclined(payment, reason: PaymentDeclineReason.fromCode(error.code));
      return;
    }
    if (method == PaymentMethod.cash) {
      _state.value = PaymentChoosing(payment, selected: method);
      Toast.error(genericFailure);
      return;
    }
    _state.value = PaymentFailed(payment, method: method);
  }

  Future<void> cancelCash() async {
    final id = _tripId;
    final current = state;
    if (id == null || current is! PaymentAwaitingDriver) return;
    final epoch = _invalidate();
    try {
      final response = await _api.post(MockEndpoints.tripPaymentCancelOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      _apply(TripPayment.fromJson(_dataOf(response.data)), epoch);
    } catch (e) {
      log('cancel cash failed: $e');
      if (epoch != _epoch) return;
      _startPolling(epoch);
      Toast.error(genericFailure);
    }
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  void _startPolling(int epoch) {
    if (_poller != null) return;
    _poller = Timer.periodic(pollInterval, (_) => _poll(epoch));
  }

  Future<void> _poll(int epoch) async {
    final id = _tripId;
    if (_isPolling || id == null || epoch != _epoch || state is! PaymentAwaitingDriver) return;
    _isPolling = true;
    try {
      final response = await _api.get(MockEndpoints.tripPaymentOf(id), suppressErrorToast: true);
      if (epoch != _epoch || state is! PaymentAwaitingDriver) return;
      _apply(TripPayment.fromJson(_dataOf(response.data)), epoch);
    } catch (e) {
      log('payment poll failed: $e');
    } finally {
      _isPolling = false;
    }
  }

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
