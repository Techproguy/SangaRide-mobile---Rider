import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/services/card_tokenizer.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class _Attempt {
  _Attempt({required this.signature, required this.method, required this.mutation, this.cardToken});

  final String signature;
  final PaymentMethod method;
  final Mutation<TripPayment> mutation;
  final String? cardToken;
}

class TripPaymentController extends GetxController {
  static const Duration pollInterval = Duration(milliseconds: 1500);
  static const Set<String> _declineCodes = {
    'card_declined',
    'card_expired',
    'insufficient_balance',
    'group_wallet_short',
  };

  final _api = Get.find<ApiService>();
  final _wallet = Get.find<WalletController>();
  final _tokenizer = Get.find<CardTokenizer>();

  final Rx<PaymentState> _state = Rx<PaymentState>(const PaymentLoading());
  LivePoller? _poller;
  VoidCallback? _detachLink;
  Worker? _walletWorker;
  Timer? _cashTimer;
  _Attempt? _attempt;
  Mutation<TripPayment>? _cancelCashMutation;
  String? _tripId;
  int _epoch = 0;

  Rx<PaymentState> get stateRx => _state;

  PaymentState get state => _state.value;

  TripPayment? get payment => switch (state) {
    PaymentLoaded(:final payment) => payment,
    _ => null,
  };

  bool get isProcessing => state is PaymentProcessing || state is PaymentChecking;

  @override
  void onInit() {
    super.onInit();
    _walletWorker = ever(_wallet.stateRx, (_) => _onWalletChanged());
  }

  @override
  void onClose() {
    _walletWorker?.dispose();
    _invalidate();
    super.onClose();
  }

  int _invalidate() {
    _stopPolling();
    return ++_epoch;
  }

  void stopWatching() => _stopPolling();

  Future<void> open(String tripId) async {
    if (_tripId != tripId) _forgetAttempts();
    _tripId = tripId;
    await _load();
  }

  Future<void> reload() async {
    if (_tripId == null || state is PaymentLoading) return;
    await _load();
  }

  void _forgetAttempts() {
    _attempt?.mutation.dispose();
    _attempt = null;
    _cancelCashMutation?.dispose();
    _cancelCashMutation = null;
  }

  Future<void> _load() async {
    final id = _tripId;
    if (id == null) return;
    final epoch = _invalidate();
    _state.value = const PaymentLoading();
    unawaited(_wallet.open());
    try {
      final payment = await _fetchPayment(id, profile: RequestProfile.interactive);
      if (epoch != _epoch) return;
      _apply(payment, epoch);
    } catch (error) {
      log('payment load failed: ${error.runtimeType}', name: 'TripPayment');
      if (epoch == _epoch) _state.value = PaymentUnavailable(PaymentProblem.of(error));
    }
  }

  Future<TripPayment> _fetchPayment(String id, {RequestProfile profile = RequestProfile.background}) async {
    final response = await _api.get(AppEndpoints.tripPaymentOf(id), suppressErrorToast: true, profile: profile);
    return TripPayment.fromJson(_dataOf(response.data));
  }

  void _apply(TripPayment payment, int epoch) {
    switch (payment.status) {
      case PaymentStatus.succeeded:
        _stopPolling();
        _settleWallets(payment);
        _state.value = PaymentPaid(payment);
      case PaymentStatus.awaitingDriver:
        _state.value = PaymentAwaitingDriver(payment, link: _cashLinkOf(payment));
        _startPolling(epoch);
        _scheduleCashDeadline(payment);
      case PaymentStatus.declined || PaymentStatus.failed:
        _stopPolling();
        _state.value = PaymentDeclined(payment, reason: payment.declineReason ?? PaymentDeclineReason.unknown);
      case PaymentStatus.pending:
        _stopPolling();
        _state.value = PaymentChoosing(payment, selected: _preferredOf(payment));
      case PaymentStatus.processing || PaymentStatus.unknown:
        _state.value = PaymentChecking(payment, method: payment.method ?? PaymentMethod.card);
        _startPolling(epoch);
    }
  }

  void _settleWallets(TripPayment payment) {
    switch (payment.method) {
      case PaymentMethod.wallet:
        unawaited(_wallet.reloadQuietly());
      case PaymentMethod.groupWallet:
        _reloadGroupWallet(payment.group?.id);
      default:
        break;
    }
  }

  void _reloadGroupWallet(String? groupId) {
    if (groupId == null) return;
    final scope = WalletScope.group(groupId);
    if (Get.isRegistered<WalletController>(tag: scope.tag)) {
      unawaited(Get.find<WalletController>(tag: scope.tag).reloadQuietly());
    }
  }

  CashWaitLink _cashLinkOf(TripPayment payment) {
    final deadline = payment.cashWaitExpiresAt;
    if (deadline != null && !deadline.isAfter(DateTime.now())) return CashWaitLink.timedOut;
    return _poller?.link.value == LinkState.lost ? CashWaitLink.offline : CashWaitLink.live;
  }

  void _scheduleCashDeadline(TripPayment payment) {
    _cashTimer?.cancel();
    _cashTimer = null;
    final deadline = payment.cashWaitExpiresAt;
    if (deadline == null) return;
    final left = deadline.difference(DateTime.now());
    if (left <= Duration.zero) return;
    _cashTimer = Timer(left, () {
      final current = state;
      if (current is PaymentAwaitingDriver) _state.value = current.withLink(CashWaitLink.timedOut);
      unawaited(_poller?.refreshNow());
    });
  }

  bool _walletCovers(int fare) => WalletPayOption.from(_wallet.state, fare) is WalletCovers;

  bool _isChoosable(TripPayment payment, PaymentMethod method) =>
      payment.allowedMethods.contains(method) && (method != PaymentMethod.wallet || _walletCovers(payment.amount));

  PaymentMethod? _preferredOf(TripPayment payment) {
    if (_isChoosable(payment, PaymentMethod.groupWallet)) return PaymentMethod.groupWallet;
    final last = payment.lastMethod;
    if (last != null && _isChoosable(payment, last)) return last;
    return payment.allowedMethods.where((method) => _isChoosable(payment, method)).firstOrNull;
  }

  void _onWalletChanged() {
    final current = state;
    if (current is! PaymentChoosing || current.selected != null) return;
    final method = _preferredOf(current.payment);
    if (method != null) _state.value = PaymentChoosing(current.payment, selected: method);
  }

  void select(PaymentMethod method) {
    final current = state;
    if (current is! PaymentChoosing || !_isChoosable(current.payment, method)) return;
    _state.value = current.withSelected(method);
  }

  void beginCard() {
    final current = state;
    if (current is PaymentChoosing) _state.value = PaymentCardEntry(current.payment);
  }

  void backToChoosing() {
    final current = state;
    final payment = current is PaymentLoaded ? current.payment : null;
    if (payment == null || isProcessing || current is PaymentAwaitingDriver || current is PaymentPaid) return;
    if (current is PaymentUnconfirmed) return;
    final method = current is PaymentChoosing && current.selected != null && _isChoosable(payment, current.selected!)
        ? current.selected
        : _preferredOf(payment);
    _state.value = PaymentChoosing(payment, selected: method);
  }

  void chooseCashInstead() {
    final current = state;
    if (current is! PaymentLoaded || isProcessing || current is PaymentPaid || current is PaymentUnconfirmed) return;
    if (!current.payment.allowedMethods.contains(PaymentMethod.cash)) return;
    _state.value = PaymentChoosing(current.payment, selected: PaymentMethod.cash);
  }

  void retryCard() {
    final current = state;
    if (current is PaymentDeclined || current is PaymentCardEntry) {
      _state.value = PaymentCardEntry((current as PaymentLoaded).payment);
    }
  }

  Future<void> payCash() async {
    final current = state;
    if (current is! PaymentChoosing || current.selected != PaymentMethod.cash) return;
    await _submit(current.payment, const PaymentRequest.cash(), signature: 'cash');
  }

  Future<void> payWallet() async {
    final current = state;
    if (current is! PaymentChoosing || current.selected != PaymentMethod.wallet) return;
    await _submit(current.payment, const PaymentRequest.wallet(), signature: 'wallet');
  }

  Future<void> payGroupWallet() async {
    final current = state;
    if (current is! PaymentChoosing || current.selected != PaymentMethod.groupWallet) return;
    await _submit(current.payment, const PaymentRequest.groupWallet(), signature: 'group_wallet');
  }

  Future<void> payCard(CardDetails details) async {
    final current = state;
    if (current is! PaymentCardEntry) return;
    final payment = current.payment;
    if (LiveProblem.isOffline) {
      _state.value = PaymentCardEntry(payment, notice: PaymentNotice.offline);
      return;
    }
    final epoch = _invalidate();
    _state.value = PaymentProcessing(payment, method: PaymentMethod.card);
    final String token;
    try {
      token = await _tokenizer.tokenize(details);
    } catch (error) {
      log('card tokenisation failed: ${error.runtimeType}', name: 'TripPayment');
      if (epoch == _epoch) {
        _state.value = PaymentCardEntry(payment, notice: PaymentNotice.of(error));
      }
      return;
    }
    if (epoch != _epoch) return;
    await _run(payment, PaymentRequest.card(token), signature: 'card|$token', epoch: epoch);
  }

  Future<void> _submit(TripPayment payment, PaymentRequest request, {required String signature}) async {
    if (LiveProblem.isOffline) {
      _state.value = PaymentChoosing(payment, selected: request.method, notice: PaymentNotice.offline);
      return;
    }
    final epoch = _invalidate();
    _state.value = PaymentProcessing(payment, method: request.method);
    await _run(payment, request, signature: signature, epoch: epoch);
  }

  Future<void> _run(
    TripPayment payment,
    PaymentRequest request, {
    required String signature,
    required int epoch,
  }) async {
    final id = _tripId;
    if (id == null) return;
    final attempt = _attemptFor(id, request, signature);
    final result = await attempt.mutation.start();
    if (epoch != _epoch) return;
    _settle(result, attempt, payment, epoch);
  }

  _Attempt _attemptFor(String id, PaymentRequest request, String signature) {
    final existing = _attempt;
    if (existing != null && existing.signature == signature) return existing;
    existing?.mutation.dispose();
    final mutation = Mutation<TripPayment>(
      intent: 'trip-pay',
      run: (key) async {
        final response = await _api.post(
          AppEndpoints.tripPaymentOf(id),
          data: request.toJson(),
          key: key,
          suppressErrorToast: true,
        );
        return TripPayment.fromJson(_dataOf(response.data));
      },
      reconcile: () => _reconcile(id),
    );
    final attempt = _Attempt(
      signature: signature,
      method: request.method,
      mutation: mutation,
      cardToken: request.cardToken,
    );
    _attempt = attempt;
    mutation.state.addListener(() => _onAttemptState(attempt));
    return attempt;
  }

  void _onAttemptState(_Attempt attempt) {
    final current = state;
    if (current is! PaymentLoaded || !identical(_attempt, attempt)) return;
    if (attempt.mutation.state.value is MutationChecking<TripPayment>) {
      _state.value = PaymentChecking(current.payment, method: attempt.method);
    }
  }

  Future<Reconciled<TripPayment>> _reconcile(String id) async {
    final fresh = await _fetchPayment(id, profile: RequestProfile.interactive);
    return switch (fresh.status) {
      PaymentStatus.pending => const ReconciledNotDone(),
      PaymentStatus.unknown => const ReconciledPending(),
      _ => ReconciledDone(fresh),
    };
  }

  void _settle(MutationState<TripPayment> result, _Attempt attempt, TripPayment payment, int epoch) {
    switch (result) {
      case MutationDone<TripPayment>(:final value):
        _attempt?.mutation.dispose();
        _attempt = null;
        _apply(value, epoch);
      case MutationRejected<TripPayment>(:final error):
        _dropAttempt();
        _onRejected(error, payment, attempt.method);
      case MutationFailed<TripPayment>(:final error):
        _onNotSent(error, payment, attempt.method);
      case MutationUnknown<TripPayment>():
        _state.value = PaymentUnconfirmed(payment, method: attempt.method);
      default:
        break;
    }
  }

  void _dropAttempt() {
    _attempt?.mutation.dispose();
    _attempt = null;
  }

  void _onRejected(ApiException error, TripPayment payment, PaymentMethod method) {
    final code = error.code;
    if (code == 'already_paid') {
      unawaited(_load());
      return;
    }
    if (error.statusCode == 402 || _declineCodes.contains(code)) {
      if (code == PaymentDeclineReason.insufficientBalance.code) unawaited(_wallet.reloadQuietly());
      _state.value = PaymentDeclined(payment, reason: PaymentDeclineReason.fromCode(code));
      return;
    }
    final notice = PaymentNotice(PaymentProblem.unknown, serverMessage: error.message);
    _state.value = method == PaymentMethod.card
        ? PaymentCardEntry(payment, notice: notice)
        : PaymentChoosing(payment, selected: method, notice: notice);
  }

  void _onNotSent(ApiException error, TripPayment payment, PaymentMethod method) {
    final notice = PaymentNotice.of(error);
    _state.value = method == PaymentMethod.card
        ? PaymentCardEntry(payment, notice: notice)
        : PaymentChoosing(payment, selected: method, notice: notice);
  }

  Future<void> checkAgain() async {
    final current = state;
    final attempt = _attempt;
    if (current is! PaymentUnconfirmed || attempt == null) {
      await reload();
      return;
    }
    final epoch = _invalidate();
    _state.value = PaymentChecking(current.payment, method: current.method);
    final result = await attempt.mutation.recheck();
    if (epoch != _epoch) return;
    _settle(result, attempt, current.payment, epoch);
  }

  Future<void> cancelCash() async {
    final id = _tripId;
    final current = state;
    if (id == null || current is! PaymentAwaitingDriver) return;
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return;
    }
    final epoch = _invalidate();
    final mutation = _cancelCashMutation ??= Mutation<TripPayment>(
      intent: 'trip-pay-cancel',
      run: (key) async {
        final response = await _api.post(AppEndpoints.tripPaymentCancelOf(id), key: key, suppressErrorToast: true);
        return TripPayment.fromJson(_dataOf(response.data));
      },
      reconcile: () async {
        final fresh = await _fetchPayment(id, profile: RequestProfile.interactive);
        return fresh.status == PaymentStatus.awaitingDriver ? const ReconciledNotDone() : ReconciledDone(fresh);
      },
    );
    final result = await mutation.start();
    if (epoch != _epoch) return;
    switch (result) {
      case MutationDone<TripPayment>(:final value):
        _cancelCashMutation?.dispose();
        _cancelCashMutation = null;
        _apply(value, epoch);
      case MutationRejected<TripPayment>(:final error):
        _cancelCashMutation?.dispose();
        _cancelCashMutation = null;
        if (error.code == 'already_paid') {
          unawaited(_load());
        } else {
          LiveProblem.toast(error);
          _apply(current.payment, epoch);
        }
      case MutationFailed<TripPayment>(:final error):
        LiveProblem.toast(error);
        _state.value = current;
        _startPolling(epoch);
      case MutationUnknown<TripPayment>():
        SangaToast.show(LiveProblem.checking, tone: SangaToastTone.warning);
        _state.value = current;
        _startPolling(epoch);
      default:
        break;
    }
  }

  void _stopPolling() {
    _cashTimer?.cancel();
    _cashTimer = null;
    _detachLink?.call();
    _detachLink = null;
    _poller?.dispose();
    _poller = null;
  }

  void _startPolling(int epoch) {
    if (_poller != null) return;
    final poller = LivePoller(fetch: () => _pollOnce(epoch), interval: pollInterval);
    void mirror() => _onPollLink(poller.link.value);
    poller.link.addListener(mirror);
    _detachLink = () => poller.link.removeListener(mirror);
    _poller = poller;
    poller.start();
  }

  void _onPollLink(LinkState link) {
    final current = state;
    if (current is! PaymentAwaitingDriver || current.link == CashWaitLink.timedOut) return;
    _state.value = current.withLink(link == LinkState.lost ? CashWaitLink.offline : CashWaitLink.live);
  }

  Future<void> _pollOnce(int epoch) async {
    final id = _tripId;
    final current = state;
    if (id == null || epoch != _epoch || (current is! PaymentAwaitingDriver && current is! PaymentChecking)) return;
    final fresh = await _fetchPayment(id);
    if (epoch != _epoch) return;
    final latest = state;
    if (latest is! PaymentAwaitingDriver && latest is! PaymentChecking) return;
    _apply(fresh, epoch);
  }

  Map<String, dynamic> _dataOf(dynamic body) => JsonReader.of(JsonReader.of(body).raw['data']).raw;
}
