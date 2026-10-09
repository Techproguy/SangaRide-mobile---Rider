import 'package:sanga_ride/model/groups/group_kind.dart';
import 'package:sanga_ride/model/groups/group_member.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

export 'package:sanga_ride/model/groups/group_failure.dart';
export 'package:sanga_ride/model/groups/group_kind.dart';
export 'package:sanga_ride/model/groups/group_member.dart';
export 'package:sanga_ride/model/groups/group_state.dart';

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

  factory GroupSummary.fromReader(JsonReader reader) => GroupSummary(
    id: reader.str('id'),
    kind: GroupKind.fromCode(reader.strOrNull('kind')),
    name: reader.strOr('name', ''),
    role: GroupRole.fromCode(reader.strOrNull('role')),
    membersCount: reader.intOr('membersCount', 0),
    walletBalance: reader.intOr('walletBalance', 0),
    photoUrl: reader.strOrNull('photoUrl'),
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

  factory GroupInvite.fromReader(JsonReader reader) => GroupInvite(
    id: reader.str('id'),
    groupName: reader.strOr('groupName', ''),
    kind: GroupKind.fromCode(reader.strOrNull('kind')),
    invitedBy: reader.strOr('invitedBy', ''),
    expiresAt: reader.time('expiresAt').toLocal(),
  );

  final String id;
  final String groupName;
  final GroupKind kind;
  final String invitedBy;
  final DateTime expiresAt;
}

class GroupsOverview {
  const GroupsOverview({required this.groups, required this.invites});

  factory GroupsOverview.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return GroupsOverview(
      groups: reader.listOf('groups', GroupSummary.fromReader),
      invites: reader.listOf('invites', GroupInvite.fromReader),
    );
  }

  final List<GroupSummary> groups;
  final List<GroupInvite> invites;

  GroupSummary? groupOf(GroupKind kind) => groups.where((group) => group.kind == kind).firstOrNull;

  List<GroupInvite> invitesOf(GroupKind kind) => [
    for (final invite in invites)
      if (invite.kind == kind) invite,
  ];
}

class GroupCompany {
  const GroupCompany({required this.rcNumber, required this.address});

  factory GroupCompany.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return GroupCompany(rcNumber: reader.strOrNull('rcNumber'), address: reader.strOrNull('address'));
  }

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
    required this.members,
    required this.recentRides,
    required this.company,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final company = reader.objectOrNull('company');
    return GroupDetail(
      id: reader.str('id'),
      kind: GroupKind.fromCode(reader.strOrNull('kind')),
      name: reader.strOr('name', ''),
      role: GroupRole.fromCode(reader.strOrNull('role')),
      inviteCode: reader.strOr('inviteCode', ''),
      members: reader.listOf('members', (member) => GroupMember.fromJson(member.raw)),
      recentRides: reader.listOf('recentRides', (ride) => HistoryItem.fromJson(ride.raw)),
      company: company == null ? null : GroupCompany.fromJson(company.raw),
    );
  }

  final String id;
  final GroupKind kind;
  final String name;
  final GroupRole role;
  final String inviteCode;
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
      enumByCode(values, code, (status) => status.code, ApprovalStatus.pending);
}

class RideApproval {
  const RideApproval({required this.id, required this.status});

  factory RideApproval.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return RideApproval(id: reader.str('id'), status: ApprovalStatus.fromCode(reader.strOrNull('status')));
  }

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
    this.expiresAt,
  });

  factory GroupApproval.fromReader(JsonReader reader) => GroupApproval(
    id: reader.str('id'),
    memberId: reader.strOr('memberId', ''),
    memberName: reader.strOr('memberName', 'Someone'),
    fare: reader.intOr('fare', 0),
    pickup: reader.object('pickup').strOr('name', ''),
    dropoff: reader.object('dropoff').strOr('name', ''),
    purpose: reader.strOrNull('purpose'),
    requestedAt: reader.time('requestedAt').toLocal(),
    expiresAt: reader.timeOrNull('expiresAt'),
  );

  final String id;
  final String memberId;
  final String memberName;
  final int fare;
  final String pickup;
  final String dropoff;
  final String? purpose;
  final DateTime requestedAt;
  final DateTime? expiresAt;

  String get firstName => memberName.trim().split(RegExp(r'\s+')).first;
}

class PendingApproval {
  const PendingApproval(this.id);

  factory PendingApproval.fromData(Map<String, dynamic> data) => PendingApproval(JsonReader(data).str('approvalId'));

  final String id;
}
