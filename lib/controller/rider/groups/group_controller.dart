import 'dart:async';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/group_mutations.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/group_endpoints.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class GroupController extends GetxController {
  GroupController(this.groupId);

  final String groupId;
  final _api = Get.find<ApiService>();
  final _mutations = GroupMutations();

  final Rx<GroupDetailState> _state = Rx<GroupDetailState>(const GroupDetailLoading());
  final Rx<ApprovalsState> _approvals = Rx<ApprovalsState>(const ApprovalsLoading());
  final RxBool _isBusy = false.obs;
  StreamSubscription<void>? _resumeSubscription;
  int _epoch = 0;
  int _approvalsEpoch = 0;

  Rx<GroupDetailState> get stateRx => _state;

  GroupDetailState get state => _state.value;

  ApprovalsState get approvalsState => _approvals.value;

  bool get isBusy => _isBusy.value;

  GroupDetail? get detail => switch (state) {
    GroupDetailLoaded(:final detail) => detail,
    _ => null,
  };

  GroupMember? get me {
    final userId = Get.find<UserController>().user?.id;
    return userId == null ? null : detail?.memberOf(userId);
  }

  int get pendingApprovalCount => switch (approvalsState) {
    ApprovalsLoaded(:final approvals) => approvals.length,
    _ => 0,
  };

  bool canManageMember(GroupMember member) {
    final current = detail;
    final mine = me;
    if (current == null || mine == null || member.id == mine.id) return false;
    if (current.role == GroupRole.owner) return true;
    return current.role == GroupRole.admin && member.role == GroupRole.member;
  }

  @override
  void onInit() {
    super.onInit();
    _resumeSubscription = AppLifecycle.instance.onResume.listen((_) {
      if (state is GroupDetailLoaded) unawaited(reloadQuietly());
    });
  }

  @override
  void onClose() {
    _resumeSubscription?.cancel();
    _mutations.dispose();
    _epoch++;
    _approvalsEpoch++;
    super.onClose();
  }

  Future<void> open() async {
    if (state is GroupDetailLoaded) return reloadQuietly();
    await reload();
  }

  Future<void> reload() async {
    _state.value = const GroupDetailLoading();
    await reloadQuietly();
  }

  Future<void> reloadQuietly() async {
    final epoch = ++_epoch;
    try {
      final response = await _api.get(GroupEndpoints.groupOf(groupId), suppressErrorToast: true);
      if (epoch != _epoch) return;
      final loaded = GroupDetail.fromJson(_dataOf(response.data));
      _state.value = GroupDetailLoaded(loaded);
      if (loaded.canManage) {
        unawaited(loadApprovals());
      } else {
        _approvals.value = const ApprovalsUnavailable();
      }
    } on Object catch (error) {
      if (epoch != _epoch) return;
      final failure = GroupFailure.of(error);
      final current = state;
      if (failure.isGone) {
        _state.value = GroupDetailFailed(GroupFailure.groupNotFound);
        _approvals.value = const ApprovalsUnavailable();
        unawaited(Get.find<GroupsController>().reloadQuietly());
      } else if (current is GroupDetailLoaded) {
        _state.value = GroupDetailLoaded(current.detail, isStale: true);
      } else {
        _state.value = GroupDetailFailed(failure);
      }
    }
  }

  Future<GroupFailure?> updateMember(String memberId, MemberPatch patch, {GroupMember? base}) async {
    final current = detail;
    final member = current?.memberOf(memberId);
    if (current == null || member == null) return GroupFailure.memberNotFound;
    final changes = patch.changesAgainst(base ?? member);
    if (changes.isEmpty) return null;
    if (isBusy) return GroupFailure.connection;
    _isBusy.value = true;
    try {
      final result = await _mutations.run<GroupMember>(
        signature: 'member:$memberId:${changes.toString()}',
        intent: 'member-update',
        send: (key) async {
          final response = await _api.patch(
            GroupEndpoints.memberOf(groupId, memberId),
            data: changes,
            key: key,
            suppressErrorToast: true,
          );
          return GroupMember.fromJson(_dataOf(response.data));
        },
        reconcile: () async {
          await reloadQuietly();
          final reloaded = detail?.memberOf(memberId);
          final applied = reloaded != null && patch.changesAgainst(reloaded).isEmpty;
          return applied ? ReconciledDone<GroupMember>(reloaded) : const ReconciledNotDone<GroupMember>();
        },
      );
      final updated = result.value;
      final latest = detail;
      if (updated != null && latest != null) _state.value = GroupDetailLoaded(latest.withMember(updated));
      return _afterFailure(result.failure, memberId: memberId);
    } finally {
      _isBusy.value = false;
    }
  }

  Future<GroupFailure?> removeMember(String memberId) async {
    if (isBusy) return GroupFailure.connection;
    _isBusy.value = true;
    try {
      final result = await _mutations.run<void>(
        signature: 'remove:$memberId',
        intent: 'member-remove',
        send: (key) async {
          await _api.delete(GroupEndpoints.memberOf(groupId, memberId), key: key, suppressErrorToast: true);
        },
        reconcile: () async {
          await reloadQuietly();
          final stillThere = detail?.memberOf(memberId) != null;
          return stillThere ? const ReconciledNotDone<void>() : const ReconciledDone<void>(null);
        },
      );
      if (result.isDone) {
        _dropMember(memberId);
        unawaited(Get.find<GroupsController>().reloadQuietly());
      }
      return _afterFailure(result.failure, memberId: memberId);
    } finally {
      _isBusy.value = false;
    }
  }

  Future<GroupOutcome> invite({required String phone, required String relation, required GroupRole role}) async {
    if (isBusy) return const GroupRejected(GroupFailure.connection);
    _isBusy.value = true;
    try {
      final result = await _mutations.run<GroupMember>(
        signature: 'invite:$phone',
        intent: 'group-invite',
        send: (key) async {
          final response = await _api.post(
            GroupEndpoints.invitesOf(groupId),
            data: {'phone': phone, 'relation': relation, 'role': role.code},
            key: key,
            suppressErrorToast: true,
          );
          return GroupMember.fromJson(_dataOf(response.data));
        },
        reconcile: () async {
          await reloadQuietly();
          final invited = detail?.members
              .where(
                (member) => member.phone.replaceAll(RegExp(r'\D'), '').endsWith(phone.replaceAll(RegExp(r'\D'), '')),
              )
              .firstOrNull;
          return invited == null ? const ReconciledNotDone<GroupMember>() : ReconciledDone<GroupMember>(invited);
        },
      );
      final member = result.value;
      final latest = detail;
      if (member != null && latest != null && latest.memberOf(member.id) == null) {
        _state.value = GroupDetailLoaded(
          GroupDetail(
            id: latest.id,
            kind: latest.kind,
            name: latest.name,
            role: latest.role,
            inviteCode: latest.inviteCode,
            members: [...latest.members, member],
            recentRides: latest.recentRides,
            company: latest.company,
          ),
        );
      }
      final failure = result.failure;
      return failure == null ? const GroupDone() : GroupRejected(failure);
    } finally {
      _isBusy.value = false;
    }
  }

  Future<GroupFailure?> leave() async {
    if (isBusy) return GroupFailure.connection;
    _isBusy.value = true;
    try {
      final result = await _mutations.run<void>(
        signature: 'leave',
        intent: 'group-leave',
        send: (key) async {
          await _api.post(GroupEndpoints.leaveOf(groupId), key: key, suppressErrorToast: true);
        },
        reconcile: () async {
          final response = await _api.get(GroupEndpoints.groups, suppressErrorToast: true);
          final overview = GroupsOverview.fromJson(_dataOf(response.data));
          final stillIn = overview.groups.any((group) => group.id == groupId);
          return stillIn ? const ReconciledNotDone<void>() : const ReconciledDone<void>(null);
        },
      );
      if (result.isDone) unawaited(Get.find<GroupsController>().reloadQuietly());
      return result.failure;
    } finally {
      _isBusy.value = false;
    }
  }

  Future<void> loadApprovals() async {
    final epoch = ++_approvalsEpoch;
    try {
      final response = await _api.get(GroupEndpoints.approvalsOf(groupId), suppressErrorToast: true);
      if (epoch != _approvalsEpoch) return;
      final deciding = switch (approvalsState) {
        ApprovalsLoaded(:final deciding) => deciding,
        _ => null,
      };
      _approvals.value = ApprovalsLoaded(
        JsonReader(_dataOf(response.data)).listOf('approvals', GroupApproval.fromReader),
        deciding: deciding,
      );
    } on Object catch (error) {
      if (epoch != _approvalsEpoch) return;
      final failure = GroupFailure.of(error);
      final current = approvalsState;
      if (failure.isGone) {
        _approvals.value = const ApprovalsUnavailable();
      } else if (current is ApprovalsLoaded) {
        _approvals.value = ApprovalsLoaded(current.approvals, deciding: current.deciding, isStale: true);
      } else {
        _approvals.value = ApprovalsFailed(failure);
      }
    }
  }

  Future<void> retryApprovals() async {
    _approvals.value = const ApprovalsLoading();
    await loadApprovals();
  }

  Future<GroupFailure?> decide(GroupApproval approval, {required bool approve}) async {
    final current = approvalsState;
    if (current is! ApprovalsLoaded || current.deciding != null) return GroupFailure.connection;
    _approvals.value = ApprovalsLoaded(current.approvals, deciding: approval.id);
    final action = approve ? 'approve' : 'decline';
    final result = await _mutations.run<void>(
      signature: 'approval:${approval.id}:$action',
      intent: 'approval-$action',
      send: (key) async {
        final endpoint = approve
            ? GroupEndpoints.approvalApproveOf(groupId, approval.id)
            : GroupEndpoints.approvalDeclineOf(groupId, approval.id);
        await _api.post(endpoint, key: key, suppressErrorToast: true);
      },
      reconcile: () async {
        final response = await _api.get(GroupEndpoints.approvalsOf(groupId), suppressErrorToast: true);
        final open = JsonReader(_dataOf(response.data)).listOf('approvals', GroupApproval.fromReader);
        final stillOpen = open.any((item) => item.id == approval.id);
        return stillOpen ? const ReconciledNotDone<void>() : const ReconciledDone<void>(null);
      },
    );
    final failure = result.failure;
    if (failure == null || failure.closesApproval) {
      _removeApproval(approval.id);
    } else {
      final latest = approvalsState;
      if (latest is ApprovalsLoaded) _approvals.value = ApprovalsLoaded(latest.approvals);
      if (failure == GroupFailure.unconfirmed) unawaited(loadApprovals());
    }
    return failure;
  }

  GroupFailure? _afterFailure(GroupFailure? failure, {required String memberId}) {
    if (failure == GroupFailure.memberNotFound) _dropMember(memberId);
    if (failure == GroupFailure.unconfirmed) unawaited(reloadQuietly());
    if (failure != null && failure.isGone) unawaited(reloadQuietly());
    return failure;
  }

  void _dropMember(String memberId) {
    final latest = detail;
    if (latest != null) _state.value = GroupDetailLoaded(latest.withoutMember(memberId));
  }

  void _removeApproval(String id) {
    final current = approvalsState;
    if (current is! ApprovalsLoaded) return;
    _approvals.value = ApprovalsLoaded([
      for (final approval in current.approvals)
        if (approval.id != id) approval,
    ]);
  }

  Map<String, dynamic> _dataOf(dynamic body) => JsonReader.of(JsonReader.of(body).raw['data']).raw;
}
