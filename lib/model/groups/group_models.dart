import 'package:sanga_ride/model/groups/group_kind.dart';
import 'package:sanga_ride/model/groups/group_member.dart';
import 'package:sanga_ride/model/history/history_item.dart';

export 'package:sanga_ride/model/groups/group_kind.dart';
export 'package:sanga_ride/model/groups/group_member.dart';

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.kind,
    required this.name,
    required this.role,
    required this.membersCount,
    required this.walletBalance,
    required this.photoUrl,
  });

  factory GroupSummary.fromJson(Map<String, dynamic> json) => GroupSummary(
    id: json['id'] as String,
    kind: GroupKind.fromCode(json['kind'] as String?),
    name: json['name'] as String,
    role: GroupRole.fromCode(json['role'] as String?),
    membersCount: (json['membersCount'] as num).toInt(),
    walletBalance: (json['walletBalance'] as num).toInt(),
    photoUrl: json['photoUrl'] as String?,
  );

  final String id;
  final GroupKind kind;
  final String name;
  final GroupRole role;
  final int membersCount;
  final int walletBalance;
  final String? photoUrl;
}

class GroupInvite {
  const GroupInvite({
    required this.id,
    required this.groupName,
    required this.kind,
    required this.invitedBy,
    required this.expiresAt,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) => GroupInvite(
    id: json['id'] as String,
    groupName: json['groupName'] as String,
    kind: GroupKind.fromCode(json['kind'] as String?),
    invitedBy: json['invitedBy'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
  );

  final String id;
  final String groupName;
  final GroupKind kind;
  final String invitedBy;
  final DateTime expiresAt;
}

class GroupsOverview {
  const GroupsOverview({required this.groups, required this.invites});

  factory GroupsOverview.fromJson(Map<String, dynamic> json) => GroupsOverview(
    groups: [
      for (final group in json['groups'] as List) GroupSummary.fromJson(Map<String, dynamic>.from(group as Map)),
    ],
    invites: [
      for (final invite in json['invites'] as List) GroupInvite.fromJson(Map<String, dynamic>.from(invite as Map)),
    ],
  );

  final List<GroupSummary> groups;
  final List<GroupInvite> invites;

  GroupSummary? groupOf(GroupKind kind) => groups.where((group) => group.kind == kind).firstOrNull;

  List<GroupInvite> invitesOf(GroupKind kind) => [
    for (final invite in invites)
      if (invite.kind == kind) invite,
  ];
}

class GroupWallet {
  const GroupWallet({required this.balance, required this.monthSpent});

  factory GroupWallet.fromJson(Map<String, dynamic> json) =>
      GroupWallet(balance: (json['balance'] as num).toInt(), monthSpent: (json['monthSpent'] as num).toInt());

  final int balance;
  final int monthSpent;
}

class GroupCompany {
  const GroupCompany({required this.rcNumber, required this.address});

  factory GroupCompany.fromJson(Map<String, dynamic> json) =>
      GroupCompany(rcNumber: json['rcNumber'] as String?, address: json['address'] as String?);

  final String? rcNumber;
  final String? address;

  Map<String, dynamic> toJson() => {'rcNumber': rcNumber, 'address': address};

  bool get isEmpty => rcNumber == null && address == null;
}

class GroupDetail {
  const GroupDetail({
    required this.id,
    required this.kind,
    required this.name,
    required this.role,
    required this.inviteCode,
    required this.wallet,
    required this.members,
    required this.recentRides,
    required this.company,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    final company = json['company'];
    return GroupDetail(
      id: json['id'] as String,
      kind: GroupKind.fromCode(json['kind'] as String?),
      name: json['name'] as String,
      role: GroupRole.fromCode(json['role'] as String?),
      inviteCode: json['inviteCode'] as String,
      wallet: GroupWallet.fromJson(Map<String, dynamic>.from(json['wallet'] as Map)),
      members: [
        for (final member in json['members'] as List) GroupMember.fromJson(Map<String, dynamic>.from(member as Map)),
      ],
      recentRides: [
        for (final ride in (json['recentRides'] as List? ?? const []))
          HistoryItem.fromJson(Map<String, dynamic>.from(ride as Map)),
      ],
      company: company == null ? null : GroupCompany.fromJson(Map<String, dynamic>.from(company as Map)),
    );
  }

  final String id;
  final GroupKind kind;
  final String name;
  final GroupRole role;
  final String inviteCode;
  final GroupWallet wallet;
  final List<GroupMember> members;
  final List<HistoryItem> recentRides;
  final GroupCompany? company;

  bool get canManage => role.canManage;

  int get activeCount => members.where((member) => !member.isInvited).length;

  GroupMember? memberOf(String id) => members.where((member) => member.id == id).firstOrNull;

  GroupDetail withMember(GroupMember updated) => GroupDetail(
    id: id,
    kind: kind,
    name: name,
    role: role,
    inviteCode: inviteCode,
    wallet: wallet,
    members: [for (final member in members) member.id == updated.id ? updated : member],
    recentRides: recentRides,
    company: company,
  );

  GroupDetail withoutMember(String memberId) => GroupDetail(
    id: id,
    kind: kind,
    name: name,
    role: role,
    inviteCode: inviteCode,
    wallet: wallet,
    members: [
      for (final member in members)
        if (member.id != memberId) member,
    ],
    recentRides: recentRides,
    company: company,
  );

  List<String> get recentPurposes {
    final seen = <String>{};
    return [
      for (final ride in recentRides)
        if (ride.purpose case final purpose? when seen.add(purpose)) purpose,
    ];
  }
}

enum ApprovalStatus {
  pending('pending'),
  approved('approved'),
  declined('declined'),
  expired('expired');

  const ApprovalStatus(this.code);

  final String code;

  static ApprovalStatus fromCode(String? code) =>
      values.where((status) => status.code == code).firstOrNull ?? ApprovalStatus.pending;
}

class RideApproval {
  const RideApproval({required this.id, required this.status});

  factory RideApproval.fromJson(Map<String, dynamic> json) =>
      RideApproval(id: json['id'] as String, status: ApprovalStatus.fromCode(json['status'] as String?));

  final String id;
  final ApprovalStatus status;
}

class GroupApproval {
  const GroupApproval({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.fare,
    required this.pickup,
    required this.dropoff,
    required this.purpose,
    required this.requestedAt,
  });

  factory GroupApproval.fromJson(Map<String, dynamic> json) => GroupApproval(
    id: json['id'] as String,
    memberId: json['memberId'] as String,
    memberName: json['memberName'] as String,
    fare: (json['fare'] as num).toInt(),
    pickup: (json['pickup'] as Map)['name'] as String,
    dropoff: (json['dropoff'] as Map)['name'] as String,
    purpose: json['purpose'] as String?,
    requestedAt: DateTime.parse(json['requestedAt'] as String).toLocal(),
  );

  final String id;
  final String memberId;
  final String memberName;
  final int fare;
  final String pickup;
  final String dropoff;
  final String? purpose;
  final DateTime requestedAt;

  String get firstName => memberName.trim().split(RegExp(r'\s+')).first;
}

class PendingApproval {
  const PendingApproval(this.id);

  factory PendingApproval.fromData(Map<String, dynamic> data) => PendingApproval(data['approvalId'] as String);

  final String id;
}

enum GroupFailure {
  alreadyInGroup(
    'already_in_group',
    'You’re already in a group like this',
    'Leave your current one first, then you can start or join another.',
  ),
  nameRequired('name_required', 'Name your group', 'Give it a name so everyone knows what it is.'),
  invalidCode('invalid_code', 'That code doesn’t match', 'Check the code with whoever sent it and try again.'),
  expiredCode('expired_code', 'That code has expired', 'Ask for a fresh code and try again.'),
  phoneInGroup('phone_in_group', 'They’re already in', 'That number is already part of this group.'),
  invalidPhone('invalid_phone', 'We can’t text that number', 'Check the number and try again.'),
  lastAdmin('last_admin', 'Someone has to stay in charge', 'Make another person an admin first, then try again.'),
  notAllowed('not_allowed', 'Only admins can do that', 'Ask an admin of the group to do it for you.'),
  groupNotFound('group_not_found', 'We can’t find that group', 'It may have been removed. Head back and try again.'),
  inviteNotFound('invite_not_found', 'That invite is gone', 'It may have expired or been taken back.'),
  approvalNotFound('approval_not_found', 'Already handled', 'Someone already answered that request.'),
  connection('connection', 'We couldn’t reach the server', 'Check your connection and give it another go.');

  const GroupFailure(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  bool get isNotFound => this == groupNotFound;

  static GroupFailure fromCode(String? code) =>
      values.where((failure) => failure.code == code).firstOrNull ?? GroupFailure.connection;
}

enum GroupRideBlock {
  spendingLimitReached(
    'spending_limit_reached',
    'Over your monthly limit',
    'This ride goes past your monthly limit. Ask an admin to raise it, or pay for this one yourself.',
  ),
  outsideTimeWindow(
    'outside_time_window',
    'Not at this time',
    'Group rides are only allowed during set hours, and this isn’t one of them.',
  ),
  rideTypeNotAllowed(
    'ride_type_not_allowed',
    'That ride type isn’t allowed',
    'Pick one of the ride types your group allows.',
  ),
  placeNotApproved(
    'place_not_approved',
    'That place isn’t on your list',
    'Group rides can only go to places an admin approved.',
  ),
  dailyRideLimit('daily_ride_limit', 'That’s all for today', 'You’ve used up today’s group rides. Try again tomorrow.'),
  ridesNotAllowed(
    'group_rides_not_allowed',
    'Group rides are switched off',
    'An admin turned off group rides for this person.',
  ),
  approvalDeclined(
    'approval_declined',
    'Your ride wasn’t approved',
    'An admin said no to this ride. You can still book and pay another way.',
  ),
  approvalExpired(
    'approval_expired',
    'The request ran out of time',
    'Nobody answered in time. Send the ride again or ask an admin directly.',
  );

  const GroupRideBlock(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  static GroupRideBlock? tryFromCode(String? code) => values.where((block) => block.code == code).firstOrNull;
}

sealed class GroupsState {
  const GroupsState();
}

final class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

final class GroupsFailed extends GroupsState {
  const GroupsFailed();
}

final class GroupsLoaded extends GroupsState {
  const GroupsLoaded(this.overview);

  final GroupsOverview overview;
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
  const GroupDetailLoaded(this.detail);

  final GroupDetail detail;
}

sealed class ApprovalsState {
  const ApprovalsState();
}

final class ApprovalsLoading extends ApprovalsState {
  const ApprovalsLoading();
}

final class ApprovalsFailed extends ApprovalsState {
  const ApprovalsFailed();
}

final class ApprovalsLoaded extends ApprovalsState {
  const ApprovalsLoaded(this.approvals, {this.deciding});

  final List<GroupApproval> approvals;
  final String? deciding;
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
