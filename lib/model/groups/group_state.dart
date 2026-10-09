import 'package:sanga_ride/model/groups/group_models.dart';

sealed class GroupsState {
  const GroupsState();
}

final class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

final class GroupsFailed extends GroupsState {
  const GroupsFailed(this.failure);

  final GroupFailure failure;
}

final class GroupsLoaded extends GroupsState {
  const GroupsLoaded(this.overview, {this.isStale = false});

  final GroupsOverview overview;
  final bool isStale;
}

sealed class GroupDetailState {
  const GroupDetailState();
}

final class GroupDetailLoading extends GroupDetailState {
  const GroupDetailLoading();
}

final class GroupDetailFailed extends GroupDetailState {
  const GroupDetailFailed(this.failure);

  final GroupFailure failure;
}

final class GroupDetailLoaded extends GroupDetailState {
  const GroupDetailLoaded(this.detail, {this.isStale = false});

  final GroupDetail detail;
  final bool isStale;
}

sealed class ApprovalsState {
  const ApprovalsState();
}

final class ApprovalsLoading extends ApprovalsState {
  const ApprovalsLoading();
}

final class ApprovalsFailed extends ApprovalsState {
  const ApprovalsFailed(this.failure);

  final GroupFailure failure;
}

final class ApprovalsUnavailable extends ApprovalsState {
  const ApprovalsUnavailable();
}

final class ApprovalsLoaded extends ApprovalsState {
  const ApprovalsLoaded(this.approvals, {this.deciding, this.isStale = false});

  final List<GroupApproval> approvals;
  final String? deciding;
  final bool isStale;
}

sealed class GroupOutcome {
  const GroupOutcome();
}

final class GroupDone extends GroupOutcome {
  const GroupDone([this.groupId]);

  final String? groupId;
}

final class GroupRejected extends GroupOutcome {
  const GroupRejected(this.failure);

  final GroupFailure failure;
}
