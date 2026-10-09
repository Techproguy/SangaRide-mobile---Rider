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

  static String groupOf(String id) => group.replaceFirst(':id', id);

  static String invitesOf(String id) => invites.replaceFirst(':id', id);

  static String memberOf(String id, String memberId) =>
      members.replaceFirst(':id', id).replaceFirst(':memberId', memberId);

  static String leaveOf(String id) => leave.replaceFirst(':id', id);

  static String approvalsOf(String id) => approvals.replaceFirst(':id', id);

  static String approvalApproveOf(String id, String approvalId) =>
      approvalApprove.replaceFirst(':id', id).replaceFirst(':approvalId', approvalId);

  static String approvalDeclineOf(String id, String approvalId) =>
      approvalDecline.replaceFirst(':id', id).replaceFirst(':approvalId', approvalId);

  static String ridesOf(String id) => rides.replaceFirst(':id', id);

  static String approvalAt(String id) => approval.replaceFirst(':id', id);

  static String inviteAcceptOf(String inviteId) => inviteAccept.replaceFirst(':inviteId', inviteId);

  static String inviteDeclineOf(String inviteId) => inviteDecline.replaceFirst(':inviteId', inviteId);
}
