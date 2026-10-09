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

  static const String back = 'Back';
  static const String tryAgain = 'Try again';
  static const String confirm = 'Confirm';
  static const String optional = 'Optional';
  static const String copy = 'Copy';
  static const String share = 'Share';
  static const String review = 'Review';
  static const String decline = 'Decline';
  static const String accept = 'Accept';
  static const String approve = 'Approve';
  static const String keep = 'Keep';
  static const String leave = 'Leave';
  static const String stay = 'Stay';
  static const String join = 'Join';
  static const String everyone = 'Everyone';
  static const String from = 'From';
  static const String to = 'To';
  static const String tabMembers = 'Members';
  static const String tabWallet = 'Wallet';
  static const String tabRides = 'Rides';
  static const String familyAndBusiness = 'Family and business';
  static const String loadFailed = 'We couldn’t load this';
  static const String inviteDeclined = 'Invite declined';
  static const String requestsLoadFailed = 'We couldn’t load the requests';
  static const String requestsUnavailableTitle = 'No longer available';
  static const String requestsUnavailableMessage =
      'You can’t see these requests any more. Your role in the group may have changed.';
  static const String allCaughtUp = 'All caught up';
  static const String allCaughtUpMessage = 'When a ride goes past someone’s limit, it lands here for your OK.';
  static const String rideRequests = 'Ride requests';
  static const String requestClosed = 'This request has closed';
  static const String rcNumber = 'RC number';
  static const String companyAddress = 'Company address';
  static const String inviteSomeone = 'Invite someone';
  static const String inviteHow = 'By phone number or with the invite code';
  static const String sendInvite = 'Send invite';
  static const String whoAreTheyToYou = 'Who are they to you?';
  static const String makeThemAdmin = 'Make them an admin';
  static const String adminCan = 'Admins can invite people, set limits and top up the wallet.';
  static const String codeCopied = 'Code copied';
  static const String inviteCode = 'Invite code';
  static const String inviteCodeHint = 'XXXX-XXXX';
  static const String shareYourCode = 'Or share your invite code';
  static const String manageMember = 'Manage member';
  static const String makeAdmin = 'Make admin';
  static const String makeMember = 'Make member';
  static const String staysInWithoutManaging = 'They stay in, without managing the group.';
  static const String canManageWithYou = 'They can manage the group with you.';
  static const String notInGroupTitle = 'They’re not in the group any more';
  static const String notInGroupMessage = 'Head back to see who’s in.';
  static const String relationTitle = 'Relation';
  static const String permissionsTitle = 'Permissions';
  static const String spendingLimitTitle = 'Spending limit';
  static const String rideLimitTitle = 'Ride limit';
  static const String approvedPlacesTitle = 'Approved places';
  static const String timeWindowTitle = 'Time window';
  static const String rideTypesTitle = 'Ride types';
  static const String alertsTitle = 'Alerts';
  static const String saveSettings = 'Save settings';
  static const String placeAlreadyListed = 'That place is already on the list.';
  static const String searchForPlace = 'Search for a place';
  static const String addPlace = 'Add a place';
  static const String anywhereGoes = 'Anywhere goes';
  static const String limitRidesPerDay = 'Limit rides per day';
  static const String ridesPerDay = 'Rides per day';
  static const String rideTypesLoadFailed = 'We couldn’t load the ride types';
  static const String setMonthlyLimit = 'Set a monthly limit';
  static const String enterAmount = 'Enter amount';
  static const String overLimitHeading = 'When a ride goes over the limit';
  static const String ridesStartFrom = 'Rides can start from';
  static const String ridesRunUntil = 'Rides can run until';
  static const String onlyAtSetTimes = 'Only allow rides at set times';
  static const String pickTwoTimes = 'Pick two different times.';

  static String failureText(GroupFailure failure) => '${failure.title}. ${failure.message}';

  static String approvalDecided(String firstName, {required bool approved}) =>
      approved ? '$firstName’s ride is approved' : '$firstName’s ride was declined';

  static String inviteSent(String maskedPhone) => 'Invite sent to $maskedPhone';

  static String roleChanged(String firstName, {required bool promoted}) =>
      promoted ? '$firstName is now an admin' : '$firstName is now a member';

  static String memberRemoved(GroupMember member) =>
      member.isInvited ? 'Invite cancelled' : '${member.firstName} was removed';

  static String youLeft(String groupName) => 'You left $groupName';

  static String alertsLead(String firstName) => 'What should we ping you about for $firstName?';

  static String placesCap(int maxPlaces) => 'You can add up to $maxPlaces places.';

  static String placesLead(String firstName) =>
      'When there are places on this list, $firstName’s rides have to start or end at one of them.';

  static String noPlacesYet(String firstName) => 'No places yet, so $firstName can ride to and from anywhere.';

  static String removePlace(String label) => 'Remove $label';

  static String whoIsToYou(String firstName) => 'Who is $firstName to you?';

  static String rideCount(int count) => count == 1 ? '1 ride' : '$count rides';

  static String capRides(String firstName) => 'Cap how many group rides $firstName can take each day.';

  static String pickRideTypes(String firstName) => 'Pick the rides $firstName can book with the group wallet.';

  static String savedFor(String firstName) => 'Saved for $firstName';

  static String setAtLeast(int minimum) => 'Set at least ${WalletFormat.money(minimum)}';

  static String spendComfort(String firstName) => 'So $firstName can’t spend more than you’re comfortable with.';

  static String spentThisMonth(int amount) => 'Spent this month: ${WalletFormat.money(amount)}';

  static String outsideHours(String firstName) => 'Outside these hours, $firstName can’t book a group ride.';

  static String forPurpose(String purpose) => 'For: $purpose';

  static String fare(int amount) => 'Fare ${WalletFormat.money(amount)}';

  static String countWithCompany(String count, String company) => '$count · $company';

  static String invitesCount(int count) => count == 1 ? '1 invite' : '$count invites';

  static String shareText({required GroupKind kind, required String groupName, required String formattedCode}) =>
      'Join $groupName on Sanga Ride. Open the app, go to Menu, then ${label(kind)}, tap '
      '"${joinTile(kind)}" and enter this code: $formattedCode';

  static String anyoneCanAsk(String groupName) => 'Anyone with this code can ask to join $groupName.';

  static String youSuffix(String name) => '$name (You)';

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

  static String alertTitle(MemberAlertKind kind) => switch (kind) {
    MemberAlertKind.tripStarted => 'Trip started',
    MemberAlertKind.tripEnded => 'Trip ended',
    MemberAlertKind.sos => 'SOS alerts',
    MemberAlertKind.overLimit => 'Over the spending limit',
  };

  static String alertBody(MemberAlertKind kind, String firstName) => switch (kind) {
    MemberAlertKind.tripStarted => 'Know when $firstName’s ride gets going.',
    MemberAlertKind.tripEnded => 'Know when $firstName reaches the drop off.',
    MemberAlertKind.sos => 'Hear straight away if $firstName asks for help.',
    MemberAlertKind.overLimit => 'Hear when a ride goes past $firstName’s monthly limit.',
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
