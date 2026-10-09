part of 'ride_match_controller.dart';

extension RideMatchCancels on RideMatchController {
  Future<bool> _cancelOnServer(String id) async {
    _cancels.add(id);
    if (ConnectionMonitor.current?.isOnline == false) return false;
    try {
      await _api.post(
        AppEndpoints.rideRequestCancelOf(id),
        key: IdempotencyKey(IdempotencyIntent.cancelRideRequestKey(id)),
        suppressErrorToast: true,
      );
    } on ApiException catch (e) {
      if (e.kind != ApiFailureKind.rejected) return false;
    } catch (e) {
      log('cancel of $id failed: $e');
      return false;
    }
    _cancels.remove(id);
    _refreshRestore();
    return true;
  }

  Future<void> flushPendingCancels() async {
    if (_isFlushingCancels || _cancels.isEmpty || !SessionStorage.tokens.hasSession) return;
    _isFlushingCancels = true;
    try {
      for (final id in _cancels.ids) {
        if (!await _cancelOnServer(id)) break;
      }
    } finally {
      _isFlushingCancels = false;
    }
  }
}

class PendingRideCancels {
  final Set<String> _ids = {};

  bool get isEmpty => _ids.isEmpty;

  List<String> get ids => _ids.toList();

  bool contains(String id) => _ids.contains(id);

  void load() {
    final stored = SessionStorage.drafts.read(DraftKeys.pendingRideCancels)?['ids'];
    if (stored is! List) return;
    _ids.addAll([
      for (final id in stored)
        if (id is String) id,
    ]);
  }

  void add(String id) {
    _ids.add(id);
    _save();
  }

  void remove(String id) {
    _ids.remove(id);
    _save();
  }

  void _save() {
    if (_ids.isEmpty) {
      unawaited(SessionStorage.drafts.remove(DraftKeys.pendingRideCancels));
    } else {
      unawaited(SessionStorage.drafts.write(DraftKeys.pendingRideCancels, {'ids': ids}));
    }
  }
}
