part of 'top_up_controller.dart';

extension TopUpResume on TopUpController {
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
    final epoch = _epoch.next();
    _stopPolling();
    _draft.value = draft.copyWith(amount: () => target.amount, method: target.method);
    _state.value = TopUpSubmitting(target.method);
    try {
      final topUp = await _fetch(id);
      if (!_epoch.isCurrent(epoch)) return;
      final amount = topUp.amount ?? target.amount;
      _draft.value = draft.copyWith(amount: () => amount, method: topUp.method ?? target.method);
      await _apply(topUp, amount: amount, method: topUp.method ?? target.method, epoch: epoch);
    } on Object catch (error) {
      if (!_epoch.isCurrent(epoch)) return;
      if (error is ApiException && error.kind == ApiFailureKind.rejected) await _clearSaved();
      _state.value = TopUpFailed(TopUpFailure.of(error), method: target.method, canRetryAsIs: false);
    }
  }

  Future<void> resumeTransfer(String id) {
    return resume(SavedTopUp(intentKey: '', method: TopUpMethod.transfer, amount: draft.amount ?? 0, topUpId: id));
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
    final found = JsonReader(response.dataMapOrEmpty).listOf('topUps', (item) => TopUp.fromJson(item.raw));
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
}
