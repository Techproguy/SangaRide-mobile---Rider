import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class GroupEndpoints {
  static const String groups = '/groups';
  static const String join = '/groups/join';
  static const String inviteAccept = '/groups/invites/:inviteId/accept';
  static const String inviteDecline = '/groups/invites/:inviteId/decline';
  static const String group = '/groups/:groupId';
  static const String invites = '/groups/:groupId/invites';
  static const String members = '/groups/:groupId/members/:memberId';
  static const String leave = '/groups/:groupId/leave';
  static const String approvals = '/groups/:groupId/approvals';
  static const String approvalApprove = '/groups/:groupId/approvals/:approvalId/approve';
  static const String approvalDecline = '/groups/:groupId/approvals/:approvalId/decline';
  static const String rides = '/groups/:groupId/rides';
  static const String approval = '/approvals/:id';

  static String groupOf(String id) => fillPath(group, {'groupId': id});

  static String invitesOf(String id) => fillPath(invites, {'groupId': id});

  static String memberOf(String id, String memberId) => fillPath(members, {'groupId': id, 'memberId': memberId});

  static String leaveOf(String id) => fillPath(leave, {'groupId': id});

  static String approvalsOf(String id) => fillPath(approvals, {'groupId': id});

  static String approvalApproveOf(String id, String approvalId) =>
      fillPath(approvalApprove, {'groupId': id, 'approvalId': approvalId});

  static String approvalDeclineOf(String id, String approvalId) =>
      fillPath(approvalDecline, {'groupId': id, 'approvalId': approvalId});

  static String ridesOf(String id) => fillPath(rides, {'groupId': id});

  static String approvalAt(String id) => fillPath(approval, {'id': id});

  static String inviteAcceptOf(String inviteId) => fillPath(inviteAccept, {'inviteId': inviteId});

  static String inviteDeclineOf(String inviteId) => fillPath(inviteDecline, {'inviteId': inviteId});
}
