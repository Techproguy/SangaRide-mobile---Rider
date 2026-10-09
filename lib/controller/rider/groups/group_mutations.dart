import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class GroupMutationResult<T> {
  const GroupMutationResult.done(T this.value) : failure = null;

  const GroupMutationResult.failed(GroupFailure this.failure) : value = null;

  final T? value;
  final GroupFailure? failure;

  bool get isDone => failure == null;
}

class GroupMutations {
  final Map<String, Mutation<Object?>> _open = {};

  Future<GroupMutationResult<T>> run<T>({
    required String signature,
    required String intent,
    required Future<T> Function(IdempotencyKey key) send,
    Future<Reconciled<T>> Function()? reconcile,
  }) async {
    final existing = _open[signature] as Mutation<T>?;
    final mutation =
        existing ??
        (_open[signature] = Mutation<T>(intent: intent, run: send, reconcile: reconcile) as Mutation<Object?>)
            as Mutation<T>;
    final state = switch (mutation.state.value) {
      MutationUnknown<T>() => await mutation.recheck(),
      MutationFailed<T>() => await _retry(mutation),
      _ => await mutation.start(),
    };
    switch (state) {
      case MutationDone<T>(:final value):
        _forget(signature);
        return GroupMutationResult<T>.done(value);
      case MutationRejected<T>(:final error):
        _forget(signature);
        return GroupMutationResult<T>.failed(GroupFailure.of(error));
      case MutationFailed<T>(:final error):
        return GroupMutationResult<T>.failed(GroupFailure.of(error));
      case MutationUnknown<T>():
        return const GroupMutationResult.failed(GroupFailure.unconfirmed);
      case MutationIdle<T>() || MutationRunning<T>() || MutationChecking<T>():
        return const GroupMutationResult.failed(GroupFailure.unknown);
    }
  }

  Future<MutationState<T>> _retry<T>(Mutation<T> mutation) {
    mutation.reset(keepKey: true);
    return mutation.start();
  }

  void _forget(String signature) {
    _open.remove(signature)?.dispose();
  }

  void dispose() {
    for (final mutation in _open.values) {
      mutation.dispose();
    }
    _open.clear();
  }
}
