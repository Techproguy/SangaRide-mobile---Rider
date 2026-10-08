import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart' show Options;
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/wallet_endpoints.dart';
import 'package:sanga_ride/core/services/card_tokenizer.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/trip/wrapup/card_details.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';

class TopUpController extends GetxController {
  static const Duration transferPollInterval = Duration(seconds: 3);
  static const Duration transferPatience = Duration(seconds: 90);
  static const Duration confirmPollInterval = Duration(seconds: 2);
  static const Duration confirmPatience = Duration(seconds: 30);
  static const String genericFailure = 'We couldn’t reach the server. Give it another go.';

  static final Options _noAutoRetry = Options(extra: {'retries': 3});

  final _api = Get.find<ApiService>();
  final _wallet = Get.find<WalletController>();
  final _tokenizer = Get.find<CardTokenizer>();

  final Rx<TopUpState> _state = Rx<TopUpState>(const TopUpEditing());
  final Rx<TopUpDraft> _draft = Rx<TopUpDraft>(const TopUpDraft());
  Timer? _poller;
  DateTime? _watchStartedAt;
  bool _isPolling = false;
  int _epoch = 0;

  Rx<TopUpState> get stateRx => _state;

  TopUpState get state => _state.value;

  Rx<TopUpDraft> get draftRx => _draft;

  TopUpDraft get draft => _draft.value;

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

  void begin({int? amount}) {
    _invalidate();
    _state.value = const TopUpEditing();
    _draft.value = TopUpDraft(amount: amount);
  }

  void prepareCard() => selectSavedCard(_wallet.overview?.savedCards.firstOrNull?.id);

  void pause() {
    if (state is TopUpTransferWatching || state is TopUpTransferDelayed || state is TopUpConfirming) _invalidate();
  }

  void setAmount(int? amount) => _draft.value = draft.copyWith(amount: () => amount);

  void chooseMethod(TopUpMethod method) => _draft.value = draft.copyWith(method: method);

  void selectSavedCard(String? cardId) => _draft.value = draft.copyWith(savedCardId: () => cardId);

  void setSaveCard(bool value) => _draft.value = draft.copyWith(saveCard: value);

  void retry() {
    if (state is TopUpFailed) _state.value = const TopUpEditing();
  }

  Future<void> submitCard(CardDetails? details) async {
    final amount = draft.amount;
    final savedCardId = draft.savedCardId;
    if (state is! TopUpEditing || amount == null || (savedCardId == null && details == null)) return;
    final epoch = _invalidate();
    _state.value = const TopUpSubmitting(TopUpMethod.card);
    final String? token;
    try {
      token = savedCardId == null ? await _tokenizer.tokenize(details!) : null;
    } catch (e) {
      log('card tokenisation failed: ${e.runtimeType}');
      if (epoch == _epoch) _state.value = const TopUpFailed(TopUpFailure.unknown, method: TopUpMethod.card);
      return;
    }
    try {
      final response = await _api.post(
        WalletEndpoints.topUps,
        data: SensitiveBody({
          'amount': amount,
          'method': TopUpMethod.card.code,
          'cardId': savedCardId,
          'card': token == null ? null : SensitiveBody({'token': token}),
          'saveCard': savedCardId == null && draft.saveCard,
        }),
        options: _noAutoRetry,
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return;
      await _apply(TopUp.fromJson(_dataOf(response.data)), amount: amount, method: TopUpMethod.card, epoch: epoch);
    } catch (e) {
      log('card top up failed: ${_describe(e)}');
      if (epoch == _epoch) _state.value = TopUpFailed(_failureOf(e), method: TopUpMethod.card);
    }
  }

  Future<void> submitOtp(String code) async {
    final current = state;
    final amount = draft.amount;
    if (current is! TopUpOtp || current.stage == OtpStage.verifying || amount == null) return;
    final epoch = _invalidate();
    _state.value = current.withStage(OtpStage.verifying);
    try {
      final response = await _api.post(
        WalletEndpoints.topUpAuthorizeOf(current.topUp.id),
        data: SensitiveBody({'otp': code}),
        options: _noAutoRetry,
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return;
      await _apply(TopUp.fromJson(_dataOf(response.data)), amount: amount, method: TopUpMethod.card, epoch: epoch);
    } catch (e) {
      log('top up authorize failed: ${_describe(e)}');
      if (epoch != _epoch) return;
      if (e is ApiException && e.code == 'otp_mismatch') {
        _state.value = current.withStage(OtpStage.mismatch);
        return;
      }
      _state.value = TopUpFailed(_failureOf(e), method: TopUpMethod.card);
    }
  }

  void editOtp() {
    final current = state;
    if (current is TopUpOtp && current.stage == OtpStage.mismatch) _state.value = current.withStage(OtpStage.ready);
  }

  void cancelOtp() {
    if (state is TopUpOtp) _state.value = const TopUpEditing();
  }

  Future<void> confirmTransfer() async {
    final amount = draft.amount;
    if (state is! TopUpEditing || amount == null) return;
    final epoch = _invalidate();
    _state.value = const TopUpSubmitting(TopUpMethod.transfer);
    try {
      final response = await _api.post(
        WalletEndpoints.topUps,
        data: {'method': TopUpMethod.transfer.code, 'amount': amount},
        options: _noAutoRetry,
        suppressErrorToast: true,
      );
      if (epoch != _epoch) return;
      await _apply(TopUp.fromJson(_dataOf(response.data)), amount: amount, method: TopUpMethod.transfer, epoch: epoch);
    } catch (e) {
      log('transfer top up failed: ${_describe(e)}');
      if (epoch != _epoch) return;
      _state.value = const TopUpEditing();
      Toast.error(genericFailure);
    }
  }

  Future<void> resumeTransfer(String id) async {
    final epoch = _invalidate();
    _state.value = const TopUpSubmitting(TopUpMethod.transfer);
    try {
      final response = await _api.get(WalletEndpoints.topUpOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      final topUp = TopUp.fromJson(_dataOf(response.data));
      _draft.value = draft.copyWith(amount: () => topUp.amount, method: TopUpMethod.transfer);
      await _apply(topUp, amount: topUp.amount ?? 0, method: TopUpMethod.transfer, epoch: epoch);
    } catch (e) {
      log('resume transfer failed: ${_describe(e)}');
      if (epoch != _epoch) return;
      _state.value = const TopUpFailed(TopUpFailure.unknown, method: TopUpMethod.transfer);
    }
  }

  void checkAgain() {
    final current = state;
    if (current is! TopUpTransferDelayed) return;
    final epoch = _invalidate();
    _state.value = TopUpTransferWatching(current.expectation);
    _startWatching(epoch);
    unawaited(_poll(epoch));
  }

  Future<void> _apply(TopUp topUp, {required int amount, required TopUpMethod method, required int epoch}) async {
    switch (topUp.status) {
      case TopUpStatus.completed:
        await _succeed(amount, method, epoch);
      case TopUpStatus.requiresAction:
        final action = topUp.action;
        if (action?.type == TopUpActionType.otp) {
          _state.value = TopUpOtp(topUp, action!);
        } else {
          _state.value = const TopUpFailed(TopUpFailure.checkNotSupported, method: TopUpMethod.card);
        }
      case TopUpStatus.pending:
        _state.value = TopUpConfirming(topUp);
        _startWatching(epoch, interval: confirmPollInterval);
      case TopUpStatus.awaitingTransfer:
        _state.value = TopUpTransferWatching(
          TransferExpectation(id: topUp.id, amount: topUp.amount ?? amount, expiresAt: topUp.expiresAt),
        );
        _startWatching(epoch);
      case TopUpStatus.expired:
        _state.value = TopUpFailed(TopUpFailure.transferExpired, method: method);
      case TopUpStatus.failed:
        _state.value = TopUpFailed(TopUpFailure.fromCode(topUp.failureCode), method: method);
    }
  }

  Future<void> _succeed(int amount, TopUpMethod method, int epoch) async {
    _poller?.cancel();
    _poller = null;
    await _wallet.reloadQuietly();
    if (epoch != _epoch) return;
    _state.value = TopUpSucceeded(amount: amount, balance: _wallet.balance, method: method);
  }

  void _startWatching(int epoch, {Duration interval = transferPollInterval}) {
    _watchStartedAt = DateTime.now();
    _poller?.cancel();
    _poller = Timer.periodic(interval, (_) => _poll(epoch));
  }

  Future<void> _poll(int epoch) async {
    final current = state;
    final id = switch (current) {
      TopUpTransferWatching(:final expectation) => expectation.id,
      TopUpConfirming(:final topUp) => topUp.id,
      _ => null,
    };
    if (_isPolling || id == null || epoch != _epoch) return;
    _isPolling = true;
    try {
      final response = await _api.get(WalletEndpoints.topUpOf(id), suppressErrorToast: true);
      if (epoch != _epoch) return;
      final topUp = TopUp.fromJson(_dataOf(response.data));
      final method = current is TopUpConfirming ? TopUpMethod.card : TopUpMethod.transfer;
      final amount = topUp.amount ?? draft.amount ?? 0;
      if (topUp.status == TopUpStatus.awaitingTransfer || topUp.status == TopUpStatus.pending) {
        _expireIfPatienceRanOut(current);
      } else {
        await _apply(topUp, amount: amount, method: method, epoch: epoch);
      }
    } catch (e) {
      log('top up poll failed: ${_describe(e)}');
      if (epoch == _epoch) _expireIfPatienceRanOut(current);
    } finally {
      _isPolling = false;
    }
  }

  void _expireIfPatienceRanOut(TopUpState current) {
    final startedAt = _watchStartedAt;
    if (startedAt == null) return;
    final waited = DateTime.now().difference(startedAt);
    if (current is TopUpTransferWatching && waited >= transferPatience) {
      _invalidate();
      _state.value = TopUpTransferDelayed(current.expectation);
    }
    if (current is TopUpConfirming && waited >= confirmPatience) {
      _invalidate();
      _state.value = const TopUpFailed(TopUpFailure.unconfirmed, method: TopUpMethod.card);
    }
  }

  TopUpFailure _failureOf(Object error) {
    if (error is ApiException) return TopUpFailure.fromCode(error.code);
    return TopUpFailure.unconfirmed;
  }

  String _describe(Object error) => error is ApiException ? '${error.code}' : '${error.runtimeType}';

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
