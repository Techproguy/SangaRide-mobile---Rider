import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';

abstract final class GroupCopy {
  static String label(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Family',
    GroupKind.business => 'Business',
  };

  static IconData icon(GroupKind kind) => switch (kind) {
    GroupKind.family => Icons.family_restroom_rounded,
    GroupKind.business => Icons.apartment_rounded,
  };

  static String hubTitle(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Sanga Family',
    GroupKind.business => 'Sanga Business',
  };

  static String hubLead(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Book rides for the people you love, set the limits, and see every trip.',
    GroupKind.business => 'One wallet for team rides, clear purposes, and no receipts to chase.',
  };

  static String createTile(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Create family group',
    GroupKind.business => 'Create business',
  };

  static String joinTile(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Join family group',
    GroupKind.business => 'Join a business',
  };

  static String nameLabel(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Family name',
    GroupKind.business => 'Business name',
  };

  static String nameHint(GroupKind kind) => switch (kind) {
    GroupKind.family => 'The Johnsons',
    GroupKind.business => 'Ray Holdings Ltd',
  };

  static String roleTitle(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Your role in the family',
    GroupKind.business => 'Your role in the business',
  };

  static String joinLead(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Got a code from someone in the family? Pop it in.',
    GroupKind.business => 'Got a code from your company? Pop it in.',
  };

  static const String invitesHeading = 'Waiting for you';

  static String inviteLine(GroupInvite invite, {DateTime? now}) {
    final days = invite.expiresAt.difference(now ?? DateTime.now()).inDays;
    final expiry = switch (days) {
      <= 0 => 'ends today',
      1 => 'ends tomorrow',
      _ => 'ends in $days days',
    };
    return 'Invited by ${invite.invitedBy} · $expiry';
  }

  static List<String> relations(GroupKind kind) => switch (kind) {
    GroupKind.family => const ['Spouse', 'Son', 'Daughter', 'Parent', 'Sibling', 'Other'],
    GroupKind.business => const ['Employee', 'Manager', 'Contractor', 'Other'],
  };

  static String memberNoun(GroupKind kind) => switch (kind) {
    GroupKind.family => 'family member',
    GroupKind.business => 'team member',
  };

  static String membersCount(int count) => count == 1 ? '1 member' : '$count members';

  static String inviteTitle(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Invite to your family',
    GroupKind.business => 'Invite to your business',
  };

  static String inviteLead(GroupKind kind) => switch (kind) {
    GroupKind.family => 'We’ll text them a link to join. You can set their limits once they’re in.',
    GroupKind.business => 'We’ll text them a link to join. You can set their limits once they’re in.',
  };

  static String walletLabel(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Family wallet',
    GroupKind.business => 'Business wallet',
  };

  static String permissionsLead(GroupKind kind, String firstName) =>
      'Choose what $firstName can do in the ${label(kind).toLowerCase()}.';

  static const String bookRidesTitle = 'Book rides';

  static String bookRidesBody(String firstName) => 'Lets $firstName book rides for themselves.';

  static const String bookForOthersTitle = 'Book for others';

  static String bookForOthersBody(GroupKind kind, String firstName) => switch (kind) {
    GroupKind.family => 'Lets $firstName book rides for other people in the family.',
    GroupKind.business => 'Lets $firstName book rides for other people on the team.',
  };

  static String useWalletTitle(GroupKind kind) => 'Use the ${walletLabel(kind).toLowerCase()}';

  static String useWalletBody(GroupKind kind, String firstName) =>
      'Lets $firstName pay for rides from the group wallet.';

  static String overLimitTitle(OverLimitAction action) => switch (action) {
    OverLimitAction.block => 'Block the ride',
    OverLimitAction.askApproval => 'Ask an admin first',
    OverLimitAction.usePersonal => 'Use their own wallet',
  };

  static String overLimitBody(OverLimitAction action, String firstName) => switch (action) {
    OverLimitAction.block => '$firstName can’t book a ride that goes past the limit.',
    OverLimitAction.askApproval => 'Admins get asked first. If one says yes, the group wallet pays.',
    OverLimitAction.usePersonal => 'The ride is paid from $firstName’s own wallet instead.',
  };

  static IconData overLimitIcon(OverLimitAction action) => switch (action) {
    OverLimitAction.block => Icons.block_rounded,
    OverLimitAction.askApproval => Icons.help_outline_rounded,
    OverLimitAction.usePersonal => Icons.account_balance_wallet_outlined,
  };

  static String alertTitle(String key) => switch (key) {
    'tripStarted' => 'Trip started',
    'tripEnded' => 'Trip ended',
    'sos' => 'SOS alerts',
    _ => 'Over the spending limit',
  };

  static String alertBody(String key, String firstName) => switch (key) {
    'tripStarted' => 'Know when $firstName’s ride gets going.',
    'tripEnded' => 'Know when $firstName reaches the drop off.',
    'sos' => 'Hear straight away if $firstName asks for help.',
    _ => 'Hear when a ride goes past $firstName’s monthly limit.',
  };

  static String spendSummary(MemberLimits limits) {
    final cap = limits.monthlySpend;
    return cap == null ? 'No limit' : '${WalletFormat.money(cap)} a month';
  }

  static String ridesSummary(MemberLimits limits) {
    final perDay = limits.ridesPerDay;
    if (perDay == null) return 'No limit';
    return perDay == 1 ? '1 ride a day' : '$perDay rides a day';
  }

  static String placesSummary(MemberLimits limits) {
    final count = limits.approvedPlaces.length;
    if (count == 0) return 'Anywhere';
    return count == 1 ? '1 place' : '$count places';
  }

  static String timeSummary(MemberLimits limits, MaterialLocalizations localizations) {
    final window = limits.timeWindow;
    if (window == null) return 'Any time';
    return '${clock(window.from, localizations)} to ${clock(window.to, localizations)}';
  }

  static String clock(String value, MaterialLocalizations localizations) {
    final (hour, minute) = TimeWindow.decode(value);
    return localizations.formatTimeOfDay(TimeOfDay(hour: hour, minute: minute)).toLowerCase();
  }

  static String typesSummary(MemberLimits limits) {
    final types = limits.rideTypes;
    if (types == null) return 'Every ride type';
    if (types.isEmpty) return 'None';
    return types.map((type) => '${type[0].toUpperCase()}${type.substring(1)}').join(', ');
  }

  static String permissionsSummary(MemberPermissions permissions) {
    final on = [permissions.bookRides, permissions.bookForOthers, permissions.useGroupWallet].where((v) => v).length;
    return '$on of 3 on';
  }

  static String alertsSummary(MemberAlerts alerts) {
    final on = [alerts.tripStarted, alerts.tripEnded, alerts.sos, alerts.overLimit].where((v) => v).length;
    return '$on of 4 on';
  }

  static String removeTitle(GroupMember member) => member.isInvited ? 'Cancel invite' : 'Remove from group';

  static String removePrompt(GroupMember member) =>
      member.isInvited ? 'Cancel the invite' : 'Remove ${member.firstName}';

  static String removeMessage(GroupMember member, String groupName) => member.isInvited
      ? 'They won’t be able to join $groupName with this invite. You can send a new one any time.'
      : '${member.firstName} will lose access to $groupName and its wallet. Their Sanga account stays.';

  static String removeAction(GroupMember member) => member.isInvited ? 'Cancel invite' : 'Remove';

  static String adminPrompt(GroupMember member) => 'Make ${member.firstName} an admin';

  static String adminMessage(GroupMember member, String groupName) =>
      '${member.firstName} will be able to invite people, set limits, top up the wallet and answer ride requests in $groupName.';

  static String demotePrompt(GroupMember member) => 'Make ${member.firstName} a member';

  static String demoteMessage(GroupMember member) =>
      '${member.firstName} won’t be able to manage the group any more. They stay in it as a regular member.';

  static String leaveTitle(GroupKind kind) => switch (kind) {
    GroupKind.family => 'Leave family group',
    GroupKind.business => 'Leave business',
  };

  static String leaveMessage(String groupName) =>
      'You’ll lose access to $groupName and its wallet. You can rejoin later with a new invite.';

  static String roleCaption(GroupMember member) {
    final status = member.isInvited ? 'Invited' : member.role.label;
    return {status, member.relation}.where((part) => part.isNotEmpty).join(' · ');
  }

  static String approvalsTitle(int count) => count == 1 ? '1 ride needs your OK' : '$count rides need your OK';

  static String approvalsSubtitle(List<GroupApproval> approvals) {
    if (approvals.isEmpty) return '';
    final first = approvals.first.firstName;
    return approvals.length == 1 ? '$first is waiting' : '$first and ${approvals.length - 1} more are waiting';
  }

  static String approvalLine(GroupApproval approval) =>
      '${approval.firstName} wants a ${WalletFormat.money(approval.fare)} ride that goes past their limit.';

  static String approvalExpiry(Duration remaining) {
    final minutes = remaining.inMinutes;
    if (minutes >= 1) return 'Closes in $minutes min';
    return 'Closes in ${remaining.inSeconds} sec';
  }
}
