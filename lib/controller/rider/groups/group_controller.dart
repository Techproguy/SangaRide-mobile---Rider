import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart' show Options;
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/group_endpoints.dart';
import 'package:sanga_ride/model/groups/group_models.dart';

class GroupController extends GetxController {
  GroupController(this.groupId);

  static final Options _noAutoRetry = Options(extra: {'retries': 3});

  final String groupId;
  final _api = Get.find<ApiService>();

  final Rx<GroupDetailState> _state = Rx<GroupDetailState>(const GroupDetailLoading());
  final Rx<ApprovalsState> _approvals = Rx<ApprovalsState>(const ApprovalsLoading());
  final RxBool _isBusy = false.obs;
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
  void onClose() {
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
      if (loaded.canManage) unawaited(loadApprovals());
    } catch (e) {
      log('group load failed: ${_describe(e)}');
      if (epoch != _epoch || state is GroupDetailLoaded) return;
      _state.value = GroupDetailFailed(GroupFailure.fromCode(e is ApiException ? e.code : null));
    }
  }

  Future<GroupFailure?> updateMember(String memberId, MemberPatch patch) async {
    final current = detail;
    if (current == null || isBusy) return GroupFailure.connection;
    _isBusy.value = true;
    try {
      final response = await _api.patch(
        GroupEndpoints.memberOf(groupId, memberId),
        data: patch.toJson(),
        options: Options(extra: {'suppressErrorToast': true}),
      );
      final updated = GroupMember.fromJson(_dataOf(response.data));
      final latest = detail;
      if (latest != null) _state.value = GroupDetailLoaded(latest.withMember(updated));
      return null;
    } catch (e) {
      log('member update failed: ${_describe(e)}');
      return _failureOf(e);
    } finally {
      _isBusy.value = false;
    }
  }

  Future<GroupFailure?> removeMember(String memberId) async {
    if (isBusy) return GroupFailure.connection;
    _isBusy.value = true;
    try {
      await _api.delete(
        GroupEndpoints.memberOf(groupId, memberId),
        options: Options(extra: {'suppressErrorToast': true}),
      );
      final latest = detail;
      if (latest != null) _state.value = GroupDetailLoaded(latest.withoutMember(memberId));
      unawaited(Get.find<GroupsController>().reloadQuietly());
      return null;
    } catch (e) {
      log('member removal failed: ${_describe(e)}');
      return _failureOf(e);
    } finally {
      _isBusy.value = false;
    }
  }

  Future<GroupOutcome> invite({required String phone, required String relation, required GroupRole role}) async {
    if (isBusy) return const GroupRejected(GroupFailure.connection);
    _isBusy.value = true;
    try {
      final response = await _api.post(
        GroupEndpoints.invitesOf(groupId),
        data: {'phone': phone, 'relation': relation, 'role': role.code},
        options: _noAutoRetry,
        suppressErrorToast: true,
      );
      final member = GroupMember.fromJson(_dataOf(response.data));
      final latest = detail;
      if (latest != null) {
        _state.value = GroupDetailLoaded(
          GroupDetail(
            id: latest.id,
            kind: latest.kind,
            name: latest.name,
            role: latest.role,
            inviteCode: latest.inviteCode,
            wallet: latest.wallet,
            members: [...latest.members, member],
            recentRides: latest.recentRides,
            company: latest.company,
          ),
        );
      }
      return const GroupDone();
    } catch (e) {
      log('invite failed: ${_describe(e)}');
      return GroupRejected(_failureOf(e));
    } finally {
      _isBusy.value = false;
    }
  }

  Future<GroupFailure?> leave() async {
    if (isBusy) return GroupFailure.connection;
    _isBusy.value = true;
    try {
      await _api.post(GroupEndpoints.leaveOf(groupId), options: _noAutoRetry, suppressErrorToast: true);
      unawaited(Get.find<GroupsController>().reloadQuietly());
      return null;
    } catch (e) {
      log('leave failed: ${_describe(e)}');
      return _failureOf(e);
    } finally {
      _isBusy.value = false;
    }
  }

  Future<void> loadApprovals() async {
    final epoch = ++_approvalsEpoch;
    try {
      final response = await _api.get(GroupEndpoints.approvalsOf(groupId), suppressErrorToast: true);
      if (epoch != _approvalsEpoch) return;
      _approvals.value = ApprovalsLoaded([
        for (final json in _dataOf(response.data)['approvals'] as List)
          GroupApproval.fromJson(Map<String, dynamic>.from(json as Map)),
      ]);
    } catch (e) {
      log('approvals load failed: ${_describe(e)}');
      if (epoch == _approvalsEpoch && approvalsState is! ApprovalsLoaded) _approvals.value = const ApprovalsFailed();
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
    try {
      final endpoint = approve
          ? GroupEndpoints.approvalApproveOf(groupId, approval.id)
          : GroupEndpoints.approvalDeclineOf(groupId, approval.id);
      await _api.post(endpoint, options: _noAutoRetry, suppressErrorToast: true);
      _removeApproval(approval.id);
      return null;
    } catch (e) {
      log('approval decision failed: ${_describe(e)}');
      final failure = _failureOf(e);
      if (failure == GroupFailure.approvalNotFound) {
        _removeApproval(approval.id);
      } else {
        _approvals.value = ApprovalsLoaded(current.approvals);
      }
      return failure;
    }
  }

  void _removeApproval(String id) {
    final current = approvalsState;
    if (current is! ApprovalsLoaded) return;
    _approvals.value = ApprovalsLoaded([
      for (final approval in current.approvals)
        if (approval.id != id) approval,
    ]);
  }

  GroupFailure _failureOf(Object error) => GroupFailure.fromCode(error is ApiException ? error.code : null);

  String _describe(Object error) => error is ApiException ? '${error.code}' : '${error.runtimeType}';

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
