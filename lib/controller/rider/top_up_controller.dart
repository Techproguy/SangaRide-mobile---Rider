import 'dart:async';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/wallet_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/wallet_endpoints.dart';
import 'package:sanga_ride/core/services/card_tokenizer.dart';
import 'package:sanga_ride/core/services/me_state.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/model/trip/wrapup/card_details.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

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
  int _epoch = 0;

  Rx<TopUpState> get stateRx => _state;

  TopUpState get state => _state.value;

  Rx<TopUpDraft> get draftRx => _draft;

  TopUpDraft get draft => _draft.value;

  Rxn<SavedTopUp> get savedRx => _saved;

  SavedTopUp? get saved => _saved.value;

  Rx<LinkState> get linkRx => _link;

  String get _draftKey => 'topup:${scope.tag ?? 'personal'}';

  @override
  void onClose() {
    _stopPolling();
    _disposeMutations();
    _epoch++;
    super.onClose();
  }

  void begin({int? amount}) {
    _stopPolling();
    _disposeMutations();
    _epoch++;
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
    final epoch = ++_epoch;
    _state.value = const TopUpSubmitting(TopUpMethod.card);
    final String? token;
    try {
      token = savedCardId == null ? await _tokenizer.tokenize(details!) : null;
    } catch (_) {
      if (epoch == _epoch) _state.value = const TopUpFailed(TopUpFailure.unknown, method: TopUpMethod.card);
      return;
    }
    if (epoch != _epoch) return;
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
    final epoch = ++_epoch;
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
    final epoch = ++_epoch;
    _stopPolling();
    _state.value = current.withStage(OtpStage.verifying);
    _authorization?.dispose();
    final topUpId = current.topUp.id;
    final mutation = Mutation<TopUp>(
      intent: 'topup-otp',
      run: (key) async {
        final response = await _api.post(
          WalletEndpoints.topUpAuthorizeAt(topUpId, groupId: scope.groupId),
          data: SensitiveBody({'otp': code}),
          key: key,
          suppressErrorToast: true,
        );
        return TopUp.fromJson(_dataOf(response.data));
      },
      reconcile: () => _reconcileById(topUpId, whileStill: TopUpStatus.requiresAction),
    );
    _authorization = mutation;
    _mirrorChecking(mutation, TopUpMethod.card, epoch);
    final result = await mutation.start();
    if (epoch != _epoch) return;
    switch (result) {
      case MutationDone<TopUp>(:final value):
        await _apply(value, amount: amount, method: TopUpMethod.card, epoch: epoch);
      case MutationRejected<TopUp>(:final error) when error.code == 'otp_mismatch':
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
    _epoch++;
    _state.value = const TopUpEditing();
  }

  Future<void> confirmTransfer() async {
    final amount = draft.amount;
    if (state is! TopUpEditing || amount == null) return;
    if (_isOffline) return _failBeforeSending(TopUpMethod.transfer);
    final epoch = ++_epoch;
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
    final epoch = ++_epoch;
    _state.value = TopUpChecking(current.method);
    final result = await mutation.recheck();
    if (epoch != _epoch) return;
    await _settle(result, method: current.method, amount: draft.amount ?? 0, epoch: epoch);
  }

  Future<SavedTopUp?> reviveSaved() async {
    var candidate = SavedTopUp.tryFromJson(SessionStorage.drafts.read(_draftKey)) ?? _fromMeState();
    if (candidate == null) {
      _saved.value = null;
      return null;
    }
    try {
      final topUp = await _lookup(candidate);
      if (topUp == null || !topUp.status.isOpen) {
        await _clearSaved();
        if (topUp?.status == TopUpStatus.completed) unawaited(_wallet.reloadQuietly());
        return null;
      }
      candidate = candidate.copyWith(topUpId: topUp.id, status: topUp.status);
    } on Object {
      _saved.value = candidate;
      return candidate;
    }
    await SessionStorage.drafts.write(_draftKey, candidate.toJson());
    _saved.value = candidate;
    return candidate;
  }

  Future<void> resume(SavedTopUp target) async {
    final id = target.topUpId;
    if (id == null) return;
    final epoch = ++_epoch;
    _stopPolling();
    _draft.value = draft.copyWith(amount: () => target.amount, method: target.method);
    _state.value = TopUpSubmitting(target.method);
    try {
      final topUp = await _fetch(id);
      if (epoch != _epoch) return;
      final amount = topUp.amount ?? target.amount;
      _draft.value = draft.copyWith(amount: () => amount, method: topUp.method ?? target.method);
      await _apply(topUp, amount: amount, method: topUp.method ?? target.method, epoch: epoch);
    } on Object catch (error) {
      if (epoch != _epoch) return;
      if (error is ApiException && error.kind == ApiFailureKind.rejected) await _clearSaved();
      _state.value = TopUpFailed(TopUpFailure.of(error), method: target.method, canRetryAsIs: false);
    }
  }

  Future<void> resumeTransfer(String id) {
    return resume(SavedTopUp(intentKey: '', method: TopUpMethod.transfer, amount: draft.amount ?? 0, topUpId: id));
  }

  Future<void> refreshNow() async {
    await _poller?.refreshNow();
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
      intent: 'topup-${method.code}',
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
        return TopUp.fromJson(_dataOf(response.data));
      },
      reconcile: () => _reconcileByKey(),
    );
    _creation = mutation;
    return mutation;
  }

  Future<void> _runCreation(Mutation<TopUp> mutation, TopUpMethod method, int amount, int epoch) async {
    _mirrorChecking(mutation, method, epoch);
    final result = await mutation.start();
    if (epoch != _epoch) return;
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
      if (epoch != _epoch) return;
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
    final found = JsonReader.of(_dataOf(response.data)).listOf('topUps', (item) => TopUp.fromJson(item.raw));
    return found.isEmpty ? const ReconciledNotDone<TopUp>() : ReconciledDone<TopUp>(found.first);
  }

  Future<Reconciled<TopUp>> _reconcileById(String id, {required TopUpStatus whileStill}) async {
    final topUp = await _fetch(id);
    if (topUp.status == whileStill) return const ReconciledNotDone<TopUp>();
    return ReconciledDone<TopUp>(topUp);
  }

  Future<TopUp> _fetch(String id) async {
    final response = await _api.get(WalletEndpoints.topUpAt(id, groupId: scope.groupId), suppressErrorToast: true);
    return TopUp.fromJson(_dataOf(response.data));
  }

  Future<TopUp?> _lookup(SavedTopUp target) async {
    final id = target.topUpId;
    if (id != null) {
      try {
        return await _fetch(id);
      } on ApiException catch (error) {
        if (error.kind == ApiFailureKind.rejected) return null;
        rethrow;
      }
    }
    if (target.intentKey.isEmpty) return null;
    final response = await _api.get(
      WalletEndpoints.topUpsOf(scope.groupId),
      queryParameters: {'idempotencyKey': target.intentKey},
      suppressErrorToast: true,
    );
    final found = JsonReader.of(_dataOf(response.data)).listOf('topUps', (item) => TopUp.fromJson(item.raw));
    return found.firstOrNull;
  }

  SavedTopUp? _fromMeState() {
    final pending = Get.find<SessionRestore>().meState?.pendingTopUps ?? const <PendingTopUp>[];
    for (final item in pending) {
      final isMine = scope.isGroup ? item.scope == 'group' && item.groupId == scope.groupId : item.scope == 'personal';
      if (!isMine) continue;
      final status = TopUpStatus.fromCode(item.status);
      return SavedTopUp(
        intentKey: '',
        method: status == TopUpStatus.awaitingTransfer ? TopUpMethod.transfer : TopUpMethod.card,
        amount: 0,
        topUpId: item.id,
        status: status,
      );
    }
    return null;
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
      if (epoch != _epoch) return;
      balance = isFresh ? _wallet.balance : null;
    } else {
      unawaited(_wallet.reloadQuietly());
    }
    _state.value = TopUpSucceeded(amount: topUp.amount ?? amount, balance: balance, method: method);
  }

  Future<void> _persistIntent(Mutation<TopUp> mutation, TopUpMethod method, int amount, String? savedCardId) {
    final intent = SavedTopUp(intentKey: mutation.key.value, method: method, amount: amount, savedCardId: savedCardId);
    _saved.value = null;
    return SessionStorage.drafts.write(_draftKey, intent.toJson());
  }

  Future<void> _remember(TopUp topUp, TopUpMethod method) async {
    final current = SavedTopUp.tryFromJson(SessionStorage.drafts.read(_draftKey));
    final base =
        current ??
        SavedTopUp(intentKey: _creation?.key.value ?? '', method: method, amount: topUp.amount ?? draft.amount ?? 0);
    final next = base.copyWith(topUpId: topUp.id, status: topUp.status);
    await SessionStorage.drafts.write(_draftKey, next.toJson());
    _saved.value = next;
    unawaited(Get.find<SessionRestore>().refreshQuietly());
  }

  Future<void> _clearSaved() async {
    _saved.value = null;
    await SessionStorage.drafts.remove(_draftKey);
    unawaited(Get.find<SessionRestore>().refreshQuietly());
  }

  void _startPolling(int epoch, Duration interval) {
    _stopPolling();
    _watchStartedAt = ServerClock.instance.now();
    final poller = LivePoller(fetch: () => _pollOnce(epoch), interval: interval);
    poller.link.addListener(() => _link.value = poller.link.value);
    _poller = poller;
    poller.start();
  }

  void _stopPolling() {
    final poller = _poller;
    _poller = null;
    _link.value = LinkState.live;
    if (poller == null) return;
    Future<void>.microtask(poller.dispose);
  }

  Future<void> _pollOnce(int epoch) async {
    final current = state;
    final id = switch (current) {
      TopUpTransferWatching(:final expectation) || TopUpTransferDelayed(:final expectation) => expectation.id,
      TopUpConfirming(:final topUp) => topUp.id,
      _ => null,
    };
    if (id == null || epoch != _epoch) return;
    final TopUp topUp;
    try {
      topUp = await _fetch(id);
    } on ApiException catch (error) {
      if (error.kind != ApiFailureKind.rejected || epoch != _epoch) rethrow;
      _stopPolling();
      await _clearSaved();
      _state.value = TopUpFailed(
        TopUpFailure.unknown,
        method: current is TopUpConfirming ? TopUpMethod.card : TopUpMethod.transfer,
      );
      return;
    }
    if (epoch != _epoch) return;
    final method = current is TopUpConfirming ? TopUpMethod.card : TopUpMethod.transfer;
    final amount = topUp.amount ?? draft.amount ?? 0;
    if (topUp.status == TopUpStatus.awaitingTransfer) {
      _markDelayedIfDue(current, topUp);
    } else if (topUp.status != TopUpStatus.pending && topUp.status != TopUpStatus.unknown) {
      _stopPolling();
      await _apply(topUp, amount: amount, method: method, epoch: epoch);
    }
  }

  void _markDelayedIfDue(TopUpState current, TopUp topUp) {
    if (current is! TopUpTransferWatching) return;
    final since = topUp.createdAt ?? _watchStartedAt ?? ServerClock.instance.now();
    if (ServerClock.instance.now().difference(since) >= transferDelayedAfter) {
      _state.value = TopUpTransferDelayed(current.expectation);
    }
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

  Map<String, dynamic> _dataOf(dynamic body) => JsonReader.of(JsonReader.of(body).raw['data']).raw;
}
