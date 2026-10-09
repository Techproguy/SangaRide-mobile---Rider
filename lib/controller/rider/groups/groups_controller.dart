import 'dart:async';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/group_mutations.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/group_endpoints.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class GroupsController extends GetxController {
  final _api = Get.find<ApiService>();
  final _mutations = GroupMutations();

  final Rx<GroupsState> _state = Rx<GroupsState>(const GroupsLoading());
  final RxBool _isBusy = false.obs;
  StreamSubscription<void>? _resumeSubscription;
  DateTime? _loadedAt;
  int _epoch = 0;

  Rx<GroupsState> get stateRx => _state;

  GroupsState get state => _state.value;

  bool get isBusy => _isBusy.value;

  GroupsOverview? get overview => switch (state) {
    GroupsLoaded(:final overview) => overview,
    _ => null,
  };

  GroupSummary? groupOf(GroupKind kind) => overview?.groupOf(kind);

  @override
  void onInit() {
    super.onInit();
    _resumeSubscription = RefreshMoments.stream.listen((_) {
      if (state is GroupsLoaded) unawaited(reloadQuietly());
    });
  }

  @override
  void onClose() {
    _resumeSubscription?.cancel();
    _mutations.dispose();
    _epoch++;
    super.onClose();
  }

  Future<void> open() async {
    if (state is GroupsLoaded) return reloadQuietly();
    await reload();
  }

  Future<void> openIfStale() async {
    final loadedAt = _loadedAt;
    final isFresh =
        state is GroupsLoaded && loadedAt != null && DateTime.now().difference(loadedAt) < const Duration(seconds: 20);
    if (!isFresh) await open();
  }

  Future<void> reload() async {
    _state.value = const GroupsLoading();
    await reloadQuietly();
  }

  Future<void> reloadQuietly() async {
    final epoch = ++_epoch;
    try {
      final response = await _api.get(GroupEndpoints.groups, suppressErrorToast: true);
      if (epoch != _epoch) return;
      _loadedAt = DateTime.now();
      _state.value = GroupsLoaded(GroupsOverview.fromJson(_dataOf(response.data)));
    } on Object catch (error) {
      if (epoch != _epoch) return;
      final current = state;
      _state.value = current is GroupsLoaded
          ? GroupsLoaded(current.overview, isStale: true)
          : GroupsFailed(GroupFailure.of(error));
    }
  }

  Future<GroupOutcome> create({
    required GroupKind kind,
    required String name,
    required String role,
    GroupCompany? company,
  }) {
    final body = {'kind': kind.code, 'name': name.trim(), 'role': role, 'company': company?.toJson()};
    return _submit(
      signature: 'create:${kind.code}:${name.trim()}:$role',
      intent: 'group-create',
      endpoint: GroupEndpoints.groups,
      body: body,
      reconcile: () => _reconcileCreate(kind, name.trim()),
    );
  }

  Future<GroupOutcome> join(String code) =>
      _submit(signature: 'join:$code', intent: 'group-join', endpoint: GroupEndpoints.join, body: {'code': code});

  Future<GroupOutcome> accept(GroupInvite invite) => _submit(
    signature: 'accept:${invite.id}',
    intent: 'invite-accept',
    endpoint: GroupEndpoints.inviteAcceptOf(invite.id),
    body: null,
    reconcile: () => _reconcileJoined(invite.kind),
  );

  Future<GroupOutcome> decline(GroupInvite invite) => _submit(
    signature: 'decline:${invite.id}',
    intent: 'invite-decline',
    endpoint: GroupEndpoints.inviteDeclineOf(invite.id),
    body: null,
    reconcile: () => _reconcileInviteGone(invite.id),
  );

  Future<GroupOutcome> _submit({
    required String signature,
    required String intent,
    required String endpoint,
    required Map<String, dynamic>? body,
    Future<Reconciled<String?>> Function()? reconcile,
  }) async {
    if (isBusy) return const GroupRejected(GroupFailure.connection);
    _isBusy.value = true;
    try {
      final result = await _mutations.run<String?>(
        signature: signature,
        intent: intent,
        send: (key) async {
          final response = await _api.post(endpoint, data: body, key: key, suppressErrorToast: true);
          final data = JsonReader.of(response.data).raw['data'];
          return JsonReader.of(data).strOrNull('id');
        },
        reconcile: reconcile,
      );
      unawaited(reloadQuietly());
      final failure = result.failure;
      return failure == null ? GroupDone(result.value) : GroupRejected(failure);
    } finally {
      _isBusy.value = false;
    }
  }

  Future<Reconciled<String?>> _reconcileCreate(GroupKind kind, String name) async {
    final overview = await _fetchOverview();
    final group = overview.groupOf(kind);
    if (group == null || group.name != name) return const ReconciledNotDone<String?>();
    return ReconciledDone<String?>(group.id);
  }

  Future<Reconciled<String?>> _reconcileJoined(GroupKind kind) async {
    final overview = await _fetchOverview();
    final group = overview.groupOf(kind);
    return group == null ? const ReconciledNotDone<String?>() : ReconciledDone<String?>(group.id);
  }

  Future<Reconciled<String?>> _reconcileInviteGone(String inviteId) async {
    final overview = await _fetchOverview();
    final stillThere = overview.invites.any((invite) => invite.id == inviteId);
    return stillThere ? const ReconciledNotDone<String?>() : const ReconciledDone<String?>(null);
  }

  Future<GroupsOverview> _fetchOverview() async {
    final response = await _api.get(GroupEndpoints.groups, suppressErrorToast: true);
    return GroupsOverview.fromJson(_dataOf(response.data));
  }

  Map<String, dynamic> _dataOf(dynamic body) => JsonReader.of(JsonReader.of(body).raw['data']).raw;
}
