import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class GroupEndpoints {
  static const String groups = '/groups';
  static const String join = '/groups/join';
  static const String invite = '/groups/invites/:inviteId';
  static const String inviteAccept = '/groups/invites/:inviteId/accept';
  static const String inviteDecline = '/groups/invites/:inviteId/decline';
  static const String group = '/groups/:id';
  static const String invites = '/groups/:id/invites';
  static const String members = '/groups/:id/members/:memberId';
  static const String leave = '/groups/:id/leave';
  static const String approvals = '/groups/:id/approvals';
  static const String approvalApprove = '/groups/:id/approvals/:approvalId/approve';
  static const String approvalDecline = '/groups/:id/approvals/:approvalId/decline';
  static const String rides = '/groups/:id/rides';
  static const String approval = '/approvals/:id';

  static String groupOf(String id) => fillPath(group, {'id': id});

  static String invitesOf(String id) => fillPath(invites, {'id': id});

  static String memberOf(String id, String memberId) => fillPath(members, {'id': id, 'memberId': memberId});

  static String leaveOf(String id) => fillPath(leave, {'id': id});

  static String approvalsOf(String id) => fillPath(approvals, {'id': id});

  static String approvalApproveOf(String id, String approvalId) =>
      fillPath(approvalApprove, {'id': id, 'approvalId': approvalId});

  static String approvalDeclineOf(String id, String approvalId) =>
      fillPath(approvalDecline, {'id': id, 'approvalId': approvalId});

  static String ridesOf(String id) => fillPath(rides, {'id': id});

  static String approvalAt(String id) => fillPath(approval, {'id': id});

  static String inviteAcceptOf(String inviteId) => fillPath(inviteAccept, {'inviteId': inviteId});

  static String inviteDeclineOf(String inviteId) => fillPath(inviteDecline, {'inviteId': inviteId});
}
