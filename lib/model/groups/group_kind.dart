import 'package:sanga_ride_core/sanga_ride_core.dart';

enum GroupKind {
  family('family'),
  business('business');

  const GroupKind(this.code);

  final String code;

  static GroupKind fromCode(String? code) => tryFromCode(code) ?? (throw JsonFormatError('Unknown group kind', code));

  static GroupKind? tryFromCode(String? code) => values.where((kind) => kind.code == code).firstOrNull;
}

enum GroupRole {
  owner('owner', 'Owner'),
  admin('admin', 'Admin'),
  member('member', 'Member');

  const GroupRole(this.code, this.label);

  final String code;
  final String label;

  bool get canManage => this != member;

  static GroupRole fromCode(String? code) => enumByCode(values, code, (role) => role.code, GroupRole.member);
}

enum MemberStatus {
  active('active'),
  invited('invited');

  const MemberStatus(this.code);

  final String code;

  static MemberStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, MemberStatus.active);
}

enum OverLimitAction {
  block('block'),
  askApproval('ask_approval'),
  usePersonal('use_personal');

  const OverLimitAction(this.code);

  final String code;

  static OverLimitAction fromCode(String? code) =>
      enumByCode(values, code, (action) => action.code, OverLimitAction.block);
}

enum CreatorRole {
  parent('parent', 'Parent', 'You look after the family and its rides.'),
  guardian('guardian', 'Guardian', 'You look after the rides of the people in your care.'),
  spouse('spouse', 'Spouse', 'You share the family with your partner.'),
  familyOther('other', 'Something else', 'You help run the family group.'),
  owner('owner', 'Owner', 'The company is yours and you run the rides.'),
  manager('manager', 'Manager', 'You manage the team and their rides.'),
  businessOther('other', 'Something else', 'You help run the company rides.');

  const CreatorRole(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  static List<CreatorRole> of(GroupKind kind) => switch (kind) {
    GroupKind.family => const [parent, guardian, spouse, familyOther],
    GroupKind.business => const [owner, manager, businessOther],
  };
}
