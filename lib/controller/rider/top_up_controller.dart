import 'dart:async';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/api/wallet_endpoints.dart';
import 'package:sanga_ride/core/services/card_tokenizer.dart';
import 'package:sanga_ride/core/services/me_state.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage/draft_keys.dart';
import 'package:sanga_ride/model/trip/wrapup/card_details.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

part 'top_up_polling.dart';
part 'top_up_resume.dart';

class TopUpController extends GetxController {
  TopUpController(this.scope);

  static const Duration transferPollInterval = Duration(seconds: 3);
  static const Duration confirmPollInterval = Duration(seconds: 2);
  static const Duration transferDelayedAfter = Duration(seconds: 90);

  final WalletScope scope;
  final _api = Get.find<ApiService>();
  late final _wallet = Get.find<WalletController>(tag: scope.tag);
  final _tokenizer = Get.find<CardTokenizer>();

  final Rx<TopUpState> _state = Rx<TopUpState>(const TopUpEditing());
  final Rx<TopUpDraft> _draft = Rx<TopUpDraft>(const TopUpDraft());
  final Rxn<SavedTopUp> _saved = Rxn<SavedTopUp>();
  final Rx<LinkState> _link = Rx<LinkState>(LinkState.live);

  Mutation<TopUp>? _creation;
  int? _creationAmount;
  String? _cardToken;
  Mutation<TopUp>? _authorization;
  LivePoller? _poller;
  DateTime? _watchStartedAt;
  final Epoch _epoch = Epoch();

  Rx<TopUpState> get stateRx => _state;

  TopUpState get state => _state.value;

  TopUpDraft get draft => _draft.value;

  SavedTopUp? get saved => _saved.value;

  Rx<LinkState> get linkRx => _link;

  String get _draftKey => DraftKeys.topUp(scope.tag);

  @override
  void onClose() {
    _stopPolling();
    _disposeMutations();
    _epoch.next();
    super.onClose();
  }

  void begin({int? amount}) {
    _stopPolling();
    _disposeMutations();
    _epoch.next();
    _state.value = const TopUpEditing();
    _draft.value = TopUpDraft(amount: amount);
  }

  void prepareCard() => selectSavedCard(_wallet.overview?.savedCards.firstOrNull?.id);

  void pause() {
    if (state is TopUpTransferWatching || state is TopUpTransferDelayed) _stopPolling();
  }

  void setAmount(int? amount) => _draft.value = draft.copyWith(amount: () => amount);

  void chooseMethod(TopUpMethod method) => _draft.value = draft.copyWith(method: method);

  void selectSavedCard(String? cardId) => _draft.value = draft.copyWith(savedCardId: () => cardId);

  void setSaveCard(bool value) => _draft.value = draft.copyWith(saveCard: value);

  void retry() {
    if (state is! TopUpFailed && state is! TopUpUnknown) return;
    _disposeCreation();
    _state.value = const TopUpEditing();
  }

  Future<void> submitCard(CardDetails? details) async {
    final amount = draft.amount;
    final savedCardId = draft.savedCardId;
    if (state is! TopUpEditing || amount == null || (savedCardId == null && details == null)) return;
    if (_isOffline) return _failBeforeSending(TopUpMethod.card);
    final epoch = _epoch.next();
    _state.value = const TopUpSubmitting(TopUpMethod.card);
    final String? token;
    try {
      token = savedCardId == null ? await _tokenizer.tokenize(details!) : null;
    } catch (_) {
      if (_epoch.isCurrent(epoch)) _state.value = const TopUpFailed(TopUpFailure.unknown, method: TopUpMethod.card);
      return;
    }
    if (!_epoch.isCurrent(epoch)) return;
    _cardToken = token;
    final mutation = _newCreation(TopUpMethod.card, amount);
    await _persistIntent(mutation, TopUpMethod.card, amount, savedCardId);
    await _runCreation(mutation, TopUpMethod.card, amount, epoch);
  }

  Future<void> retryCard() async {
    final mutation = _creation;
    final amount = draft.amount;
    final current = state;
    if (mutation == null || amount == null || current is! TopUpFailed || !current.canRetryAsIs) return;
    if (_isOffline) return _failBeforeSending(TopUpMethod.card);
    final epoch = _epoch.next();
    _state.value = const TopUpSubmitting(TopUpMethod.card);
    mutation.reset(keepKey: true);
    await _runCreation(mutation, TopUpMethod.card, amount, epoch);
  }

  Future<void> submitOtp(String code) async {
    final current = state;
    final amount = draft.amount;
    if (current is! TopUpOtp || current.stage == OtpStage.verifying || amount == null) return;
    if (_isOffline) {
      _state.value = current.withStage(OtpStage.failed, failure: TopUpFailure.connection);
      return;
    }
    final epoch = _epoch.next();
    _stopPolling();
    _state.value = current.withStage(OtpStage.verifying);
    _authorization?.dispose();
    final topUpId = current.topUp.id;
    final mutation = Mutation<TopUp>(
      intent: IdempotencyIntent.topUpOtp,
      run: (key) async {
        final response = await _api.post(
          WalletEndpoints.topUpAuthorizeAt(topUpId, groupId: scope.groupId),
          data: SensitiveBody({'otp': code}),
          key: key,
          suppressErrorToast: true,
        );
        return TopUp.fromJson(response.dataMapOrEmpty);
      },
      reconcile: () => _reconcileById(topUpId, whileStill: TopUpStatus.requiresAction),
    );
    _authorization = mutation;
    _mirrorChecking(mutation, TopUpMethod.card, epoch);
    final result = await mutation.start();
    if (!_epoch.isCurrent(epoch)) return;
    switch (result) {
      case MutationDone<TopUp>(:final value):
        await _apply(value, amount: amount, method: TopUpMethod.card, epoch: epoch);
      case MutationRejected<TopUp>(:final error) when error.code == ServerCode.otpMismatch:
        _state.value = current.withStage(OtpStage.mismatch);
      case MutationRejected<TopUp>(:final error):
        await _clearSaved();
        _state.value = TopUpFailed(TopUpFailure.of(error), method: TopUpMethod.card);
      case MutationFailed<TopUp>(:final error):
        _state.value = current.withStage(OtpStage.failed, failure: TopUpFailure.of(error));
      case MutationUnknown<TopUp>():
        _state.value = const TopUpUnknown(TopUpMethod.card);
      case MutationIdle<TopUp>() || MutationRunning<TopUp>() || MutationChecking<TopUp>():
        break;
    }
  }

  void editOtp() {
    final current = state;
    if (current is TopUpOtp && current.stage != OtpStage.ready) _state.value = current.withStage(OtpStage.ready);
  }

  void cancelOtp() {
    if (state is! TopUpOtp) return;
    _disposeMutations();
    _epoch.next();
    _state.value = const TopUpEditing();
  }

  Future<void> confirmTransfer() async {
    final amount = draft.amount;
    if (state is! TopUpEditing || amount == null) return;
    if (_isOffline) return _failBeforeSending(TopUpMethod.transfer);
    final epoch = _epoch.next();
    _state.value = const TopUpSubmitting(TopUpMethod.transfer);
    final previous = _creation;
    final isRetry = previous != null && _creationAmount == amount && previous.state.value is MutationFailed<TopUp>;
    final mutation = isRetry ? previous : _newCreation(TopUpMethod.transfer, amount);
    if (isRetry) mutation.reset(keepKey: true);
    await _persistIntent(mutation, TopUpMethod.transfer, amount, null);
    await _runCreation(mutation, TopUpMethod.transfer, amount, epoch);
  }

  void dismissFailure() {
    if (state is TopUpFailed) _state.value = const TopUpEditing();
  }

  Future<void> recheck() async {
    final current = state;
    if (current is! TopUpUnknown) return;
    final mutation = current.method == TopUpMethod.card && _authorization?.state.value is MutationUnknown<TopUp>
        ? _authorization
        : _creation;
    if (mutation == null) {
      await _wallet.reloadFresh();
      return;
    }
    final epoch = _epoch.next();
    _state.value = TopUpChecking(current.method);
    final result = await mutation.recheck();
    if (!_epoch.isCurrent(epoch)) return;
    await _settle(result, method: current.method, amount: draft.amount ?? 0, epoch: epoch);
  }

  bool get _isOffline => ConnectionMonitor.current?.isOnline == false;

  void _failBeforeSending(TopUpMethod method) {
    _state.value = TopUpFailed(TopUpFailure.connection, method: method, canRetryAsIs: _creation != null);
  }

  Mutation<TopUp> _newCreation(TopUpMethod method, int amount) {
    _disposeCreation();
    _creationAmount = amount;
    final savedCardId = draft.savedCardId;
    final saveCard = draft.saveCard;
    final token = _cardToken;
    final mutation = Mutation<TopUp>(
      intent: IdempotencyIntent.topUp(method.code),
      run: (key) async {
        final response = await _api.post(
          WalletEndpoints.topUpsOf(scope.groupId),
          data: method == TopUpMethod.card
              ? SensitiveBody({
                  'amount': amount,
                  'method': method.code,
                  'cardId': savedCardId,
                  'card': token == null ? null : SensitiveBody({'token': token}),
                  'saveCard': savedCardId == null && saveCard,
                })
              : {'method': method.code, 'amount': amount},
          key: key,
          suppressErrorToast: true,
        );
        return TopUp.fromJson(response.dataMapOrEmpty);
      },
      reconcile: () => _reconcileByKey(),
    );
    _creation = mutation;
    return mutation;
  }

  Future<void> _runCreation(Mutation<TopUp> mutation, TopUpMethod method, int amount, int epoch) async {
    _mirrorChecking(mutation, method, epoch);
    final result = await mutation.start();
    if (!_epoch.isCurrent(epoch)) return;
    await _settle(result, method: method, amount: amount, epoch: epoch);
  }

  Future<void> _settle(
    MutationState<TopUp> result, {
    required TopUpMethod method,
    required int amount,
    required int epoch,
  }) async {
    switch (result) {
      case MutationDone<TopUp>(:final value):
        await _apply(value, amount: amount, method: method, epoch: epoch);
      case MutationRejected<TopUp>(:final error):
        await _clearSaved();
        _creation?.reset();
        _state.value = TopUpFailed(TopUpFailure.of(error), method: method);
      case MutationFailed<TopUp>(:final error):
        _state.value = TopUpFailed(TopUpFailure.of(error), method: method, canRetryAsIs: true);
      case MutationUnknown<TopUp>():
        _state.value = TopUpUnknown(method);
      case MutationIdle<TopUp>() || MutationRunning<TopUp>() || MutationChecking<TopUp>():
        break;
    }
  }

  void _mirrorChecking(Mutation<TopUp> mutation, TopUpMethod method, int epoch) {
    void listener() {
      if (!_epoch.isCurrent(epoch)) return;
      if (mutation.state.value is MutationChecking<TopUp>) _state.value = TopUpChecking(method);
    }

    mutation.state.addListener(listener);
  }

  Future<Reconciled<TopUp>> _reconcileByKey() async {
    final key = _creation?.key.value;
    if (key == null) return const ReconciledPending<TopUp>();
    final response = await _api.get(
      WalletEndpoints.topUpsOf(scope.groupId),
      queryParameters: {'idempotencyKey': key},
      suppressErrorToast: true,
    );
    final found = JsonReader(response.dataMapOrEmpty).listOf('topUps', (item) => TopUp.fromJson(item.raw));
    return found.isEmpty ? const ReconciledNotDone<TopUp>() : ReconciledDone<TopUp>(found.first);
  }

  Future<Reconciled<TopUp>> _reconcileById(String id, {required TopUpStatus whileStill}) async {
    final topUp = await _fetch(id);
    if (topUp.status == whileStill) return const ReconciledNotDone<TopUp>();
    return ReconciledDone<TopUp>(topUp);
  }

  Future<TopUp> _fetch(String id) async {
    final response = await _api.get(WalletEndpoints.topUpAt(id, groupId: scope.groupId), suppressErrorToast: true);
    return TopUp.fromJson(response.dataMapOrEmpty);
  }

  Future<void> _apply(TopUp topUp, {required int amount, required TopUpMethod method, required int epoch}) async {
    switch (topUp.status) {
      case TopUpStatus.completed:
        await _succeed(topUp, amount, method, epoch);
      case TopUpStatus.requiresAction:
        final action = topUp.action;
        if (action?.type == TopUpActionType.otp) {
          await _remember(topUp, method);
          _state.value = TopUpOtp(topUp, action!);
        } else {
          await _clearSaved();
          _state.value = TopUpFailed(TopUpFailure.checkNotSupported, method: TopUpMethod.card);
        }
      case TopUpStatus.pending || TopUpStatus.unknown:
        await _remember(topUp, method);
        _state.value = TopUpConfirming(topUp);
        _startPolling(epoch, confirmPollInterval);
      case TopUpStatus.awaitingTransfer:
        await _remember(topUp, method);
        _state.value = TopUpTransferWatching(_expectationOf(topUp, amount));
        _startPolling(epoch, transferPollInterval);
      case TopUpStatus.expired:
        await _clearSaved();
        _state.value = TopUpFailed(TopUpFailure.transferExpired, method: method);
      case TopUpStatus.failed:
        await _clearSaved();
        _state.value = TopUpFailed(TopUpFailure.fromCode(topUp.failureCode), method: method);
    }
  }

  TransferExpectation _expectationOf(TopUp topUp, int amount) {
    return TransferExpectation(
      id: topUp.id,
      amount: topUp.amount ?? amount,
      expiresAt: topUp.expiresAt,
      createdAt: topUp.createdAt,
    );
  }

  Future<void> _succeed(TopUp topUp, int amount, TopUpMethod method, int epoch) async {
    _stopPolling();
    await _clearSaved();
    var balance = topUp.balance;
    if (balance == null) {
      final isFresh = await _wallet.reloadFresh();
      if (!_epoch.isCurrent(epoch)) return;
      balance = isFresh ? _wallet.balance : null;
    } else {
      unawaited(_wallet.reloadQuietly());
    }
    _state.value = TopUpSucceeded(amount: topUp.amount ?? amount, balance: balance, method: method);
  }

  void _disposeCreation() {
    _creation?.dispose();
    _creation = null;
    _creationAmount = null;
    _cardToken = null;
  }

  void _disposeMutations() {
    _disposeCreation();
    _authorization?.dispose();
    _authorization = null;
  }
}
