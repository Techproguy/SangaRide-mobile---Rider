import 'dart:math' as math;

import 'package:sanga_ride/core/api/group_endpoints.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_groups_seed.dart';
import 'package:sanga_ride/core/api/mock/mock_history.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/mock/mock_wallet.dart';

abstract final class MockGroups {
  static final List<MockRoute> routes = [
    MockRoute.get(GroupEndpoints.groups, _list),
    MockRoute.post(GroupEndpoints.groups, _create),
    MockRoute.post(GroupEndpoints.join, _join),
    MockRoute.post(GroupEndpoints.inviteAccept, _acceptInvite),
    MockRoute.post(GroupEndpoints.inviteDecline, _declineInvite),
    MockRoute.get(GroupEndpoints.group, _detail),
    MockRoute.post(GroupEndpoints.invites, _sendInvite),
    MockRoute.patch(GroupEndpoints.members, _patchMember),
    MockRoute.delete(GroupEndpoints.members, _removeMember),
    MockRoute.post(GroupEndpoints.leave, _leave),
    MockRoute.get(GroupEndpoints.approvals, _approvals),
    MockRoute.post(GroupEndpoints.approvalApprove, (request) => _decide(request, approve: true)),
    MockRoute.post(GroupEndpoints.approvalDecline, (request) => _decide(request, approve: false)),
    MockRoute.get(GroupEndpoints.rides, _rides),
    MockRoute.get(GroupEndpoints.approval, _approvalStatus),
  ];

  static const int _defaultPageSize = 10;
  static const int _maxPageSize = 50;
  static const int _recentRideCount = 5;
  static const Duration _autoApproveAfter = Duration(seconds: 8);
  static const Duration _autoDeclineAfter = Duration(seconds: 5);
  static const String _expiredCode = 'OLDCODE1';

  static final Map<String, MockGroup> _groups = {MockGroupsSeed.johnsonsId: MockGroupsSeed.johnsons()};
  static final List<String> _mine = [MockGroupsSeed.johnsonsId];
  static final List<Map<String, dynamic>> _invites = [MockGroupsSeed.kudiInvite()];
  static final Map<String, int> _requestsToday = {};
  static int _sequence = 0;

  static String get _meId => MockData.user['id'] as String;

  static String _iso(DateTime time) => time.toUtc().toIso8601String();

  static String _nextId(String prefix) => '${prefix}_${(++_sequence).toString().padLeft(3, '0')}';

  static String _digits(Object? value) => ('$value').replaceAll(RegExp(r'\D'), '');

  static String nameOf(String groupId) => _groups[groupId]?.name ?? 'Group';

  static bool canTopUp(String groupId) => _myRole(_groups[groupId]).isManager;

  static List<Map<String, dynamic>> ownedSummaries() => [
    for (final id in _mine)
      if (_myRole(_groups[id]).isOwner)
        {
          'id': id,
          'name': _groups[id]!.name,
          'kind': _groups[id]!.kind,
          'membersCount': _groups[id]!.activeCount,
          'walletBalance': MockWallet.groupBalance(id),
        },
  ];

  static MockGroup? _groupOfKind(String kind) {
    for (final id in _mine) {
      final group = _groups[id];
      if (group != null && group.kind == kind) return group;
    }
    return null;
  }

  static _Role _myRole(MockGroup? group) {
    final me = group?.memberById(_meId);
    return _Role(me?['role'] as String?);
  }

  static MockGroup _requireGroup(MockRequest request) {
    final group = _groups[request.params['id']];
    if (group == null || !_mine.contains(group.id)) {
      throw const MockFailure(404, 'We can’t find that group.', code: 'group_not_found');
    }
    return group;
  }

  static MockGroup _requireManaged(MockRequest request) {
    final group = _requireGroup(request);
    if (!_myRole(group).isManager) {
      throw const MockFailure(403, 'Only admins can do that.', code: 'not_allowed');
    }
    return group;
  }

  static Map<String, dynamic> _summary(MockGroup group) => {
    'id': group.id,
    'kind': group.kind,
    'name': group.name,
    'role': _myRole(group).code,
    'membersCount': group.activeCount,
    'walletBalance': MockWallet.groupBalance(group.id),
    'photoUrl': null,
  };

  static Object? _list(MockRequest request) {
    return {
      'groups': [for (final id in _mine) _summary(_groups[id]!)],
      'invites': [
        for (final invite in _invites)
          {
            for (final entry in invite.entries)
              if (entry.key != 'groupId') entry.key: entry.value,
          },
      ],
      'serverTime': _iso(DateTime.now()),
    };
  }

  static Object? _create(MockRequest request) {
    final kind = request.body['kind'] as String? ?? 'family';
    final name = (request.body['name'] as String? ?? '').trim();
    if (name.isEmpty) throw const MockFailure(422, 'Give your group a name.', code: 'name_required');
    if (_groupOfKind(kind) != null) {
      throw MockFailure(409, 'You’re already in a $kind group.', code: 'already_in_group');
    }
    final seq = ++_sequence;
    final id = 'grp_new_$seq';
    final company = request.body['company'];
    final group = MockGroup(
      id: id,
      kind: kind,
      name: name,
      inviteCode: '${kind == 'family' ? 'FAM' : 'BIZ'}${seq.toString().padLeft(5, '0')}',
      company: company is Map ? Map<String, dynamic>.from(company) : null,
      members: [
        MockGroupsSeed.me(role: 'owner', relation: MockGroupsSeed.relationOf(kind, request.body['role'] as String?)),
      ],
    );
    _groups[id] = group;
    _mine.add(id);
    return _summary(group);
  }

  static String _normalizeCode(Object? code) => ('$code').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static MockGroup? _groupByCode(String code) {
    for (final group in _groups.values) {
      if (group.inviteCode == code) return group;
    }
    return MockGroupsSeed.joinable(code);
  }

  static void _enter(MockGroup group, {required String relation}) {
    _groups[group.id] = group;
    group.members.add(MockGroupsSeed.me(role: 'member', relation: relation, forKind: group.kind));
    _mine.add(group.id);
  }

  static Object? _join(MockRequest request) {
    final code = _normalizeCode(request.body['code']);
    if (code == _expiredCode) throw const MockFailure(410, 'That code has expired.', code: 'expired_code');
    final group = _groupByCode(code);
    if (group == null) throw const MockFailure(404, 'That code doesn’t match a group.', code: 'invalid_code');
    if (_mine.contains(group.id) || _groupOfKind(group.kind) != null) {
      throw MockFailure(409, 'You’re already in a ${group.kind} group.', code: 'already_in_group');
    }
    _enter(group, relation: 'Employee');
    return _summary(group);
  }

  static Map<String, dynamic> _inviteOf(MockRequest request) {
    final invite = _invites.where((invite) => invite['id'] == request.params['inviteId']).firstOrNull;
    if (invite == null) throw const MockFailure(404, 'That invite is gone.', code: 'invite_not_found');
    return invite;
  }

  static Object? _acceptInvite(MockRequest request) {
    final invite = _inviteOf(request);
    final kind = invite['kind'] as String;
    if (_groupOfKind(kind) != null) {
      throw MockFailure(409, 'You’re already in a $kind group.', code: 'already_in_group');
    }
    final group = _groups[invite['groupId']] ?? MockGroupsSeed.byId(invite['groupId'] as String);
    if (group == null) throw const MockFailure(404, 'That invite is gone.', code: 'invite_not_found');
    _enter(group, relation: 'Employee');
    _invites.remove(invite);
    return _summary(group);
  }

  static Object? _declineInvite(MockRequest request) {
    _invites.remove(_inviteOf(request));
    return null;
  }

  static List<Map<String, dynamic>> _ridesOf(MockGroup group, {required String status}) {
    final parity = group.kind == 'family' ? 0 : 1;
    final members = group.activeMembers;
    final role = _myRole(group);
    final rides = <Map<String, dynamic>>[];
    for (final summary in MockHistory.summaries(status)) {
      final index = int.parse((summary['id'] as String).substring(5));
      if (index % 2 != parity || members.isEmpty) continue;
      final member = members[(index ~/ 2) % members.length];
      if (!role.isManager && member['id'] != _meId) continue;
      rides.add({
        ...summary,
        'memberId': member['id'],
        'memberName': member['name'],
        if (group.kind == 'business') 'purpose': MockGroupsSeed.purposes[(index ~/ 2) % MockGroupsSeed.purposes.length],
      });
    }
    return rides;
  }

  static Object? _detail(MockRequest request) {
    final group = _requireGroup(request);
    return {
      'id': group.id,
      'kind': group.kind,
      'name': group.name,
      'role': _myRole(group).code,
      'inviteCode': group.inviteCode,
      'wallet': {'balance': MockWallet.groupBalance(group.id), 'monthSpent': MockWallet.groupMonthSpent(group.id)},
      'members': [for (final member in group.members) group.memberJson(member)],
      'recentRides': _ridesOf(group, status: 'completed').take(_recentRideCount).toList(),
      'company': group.company,
      'serverTime': _iso(DateTime.now()),
    };
  }

  static Object? _sendInvite(MockRequest request) {
    final group = _requireManaged(request);
    final phone = _digits(request.body['phone']);
    if (!RegExp(r'^234[789]\d{9}$').hasMatch(phone)) {
      throw const MockFailure(422, 'We can’t text that number.', code: 'invalid_phone');
    }
    if (group.members.any((member) => _digits(member['phone']) == phone)) {
      throw const MockFailure(409, 'That number is already in this group.', code: 'phone_in_group');
    }
    final role = request.body['role'] == 'admin' ? 'admin' : 'member';
    final local = '0${phone.substring(3)}';
    final member = MockGroupsSeed.member(
      id: _nextId('mem'),
      name: '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}',
      phone: '+$phone',
      relation: (request.body['relation'] as String?)?.trim().isNotEmpty == true
          ? request.body['relation'] as String
          : 'Member',
      role: role,
      status: 'invited',
    );
    group.members.add(member);
    return group.memberJson(member);
  }

  static Map<String, dynamic> _memberOf(MockGroup group, MockRequest request) {
    final member = group.memberById(request.params['memberId']);
    if (member == null) throw const MockFailure(404, 'We can’t find that person.', code: 'member_not_found');
    return member;
  }

  static void _requireCanManage(MockGroup group, Map<String, dynamic> target) {
    final actor = _myRole(group);
    final targetRole = _Role(target['role'] as String?);
    final isSelf = target['id'] == _meId;
    final allowed = isSelf || actor.isOwner || (actor.isManager && !targetRole.isManager);
    if (!allowed) throw const MockFailure(403, 'Only admins can do that.', code: 'not_allowed');
  }

  static Object? _patchMember(MockRequest request) {
    final group = _requireManaged(request);
    final member = _memberOf(group, request);
    _requireCanManage(group, member);
    final body = request.body;
    final role = body['role'] as String?;
    if (role != null && role != member['role']) {
      final actor = _myRole(group);
      final isDemotion = member['role'] == 'admin' && role == 'member';
      if (member['id'] == _meId || member['role'] == 'owner' || role == 'owner' || (isDemotion && !actor.isOwner)) {
        throw const MockFailure(403, 'Only the owner can do that.', code: 'not_allowed');
      }
      member['role'] = role;
    }
    if (body['relation'] is String) member['relation'] = body['relation'];
    for (final key in const ['permissions', 'limits', 'alerts']) {
      final patch = body[key];
      if (patch is Map) (member[key] as Map<String, dynamic>).addAll(Map<String, dynamic>.from(patch));
    }
    return group.memberJson(member);
  }

  static int _managerCount(MockGroup group) => group.members
      .where((member) => _Role(member['role'] as String?).isManager && member['status'] == 'active')
      .length;

  static Object? _removeMember(MockRequest request) {
    final group = _requireManaged(request);
    final member = _memberOf(group, request);
    _requireCanManage(group, member);
    if (_Role(member['role'] as String?).isManager && _managerCount(group) <= 1) {
      throw const MockFailure(409, 'Make someone else an admin first.', code: 'last_admin');
    }
    group.members.remove(member);
    group.approvals.removeWhere((approval) => approval.memberId == member['id']);
    return null;
  }

  static Object? _leave(MockRequest request) {
    final group = _requireGroup(request);
    final me = group.memberById(_meId)!;
    final role = _myRole(group);
    if (role.isManager && _managerCount(group) <= 1 && group.activeCount > 1) {
      throw const MockFailure(409, 'Make someone else an admin first.', code: 'last_admin');
    }
    group.members.remove(me);
    if (role.isOwner) {
      final next = group.members.where((member) => member['role'] == 'admin').firstOrNull;
      next?['role'] = 'owner';
    }
    _mine.remove(group.id);
    if (group.activeCount == 0) _groups.remove(group.id);
    return {'left': true};
  }

  static Object? _rides(MockRequest request) {
    final group = _requireGroup(request);
    final status = request.query['status'] == 'cancelled' ? 'cancelled' : 'completed';
    final memberId = request.query['memberId'] as String?;
    final page = math.max(1, int.tryParse('${request.query['page'] ?? 1}') ?? 1);
    final pageSize = (int.tryParse('${request.query['pageSize'] ?? _defaultPageSize}') ?? _defaultPageSize).clamp(
      1,
      _maxPageSize,
    );
    final matching = [
      for (final ride in _ridesOf(group, status: status))
        if (memberId == null || ride['memberId'] == memberId) ride,
    ];
    final start = (page - 1) * pageSize;
    final end = math.min(start + pageSize, matching.length);
    return {
      'items': start >= matching.length ? const [] : matching.sublist(start, end),
      'page': page,
      'hasMore': end < matching.length,
      'serverTime': _iso(DateTime.now()),
    };
  }

  static void _settleAutomatic(MockApproval approval) {
    final decideAt = approval.decideAt;
    if (approval.status != 'pending' || decideAt == null || DateTime.now().isBefore(decideAt)) return;
    approval.status = approval.declineAutomatically ? 'declined' : 'approved';
  }

  static Object? _approvals(MockRequest request) {
    final group = _requireManaged(request);
    return {
      'approvals': [
        for (final approval in group.approvals)
          if (approval.isOpen) approval.toJson(),
      ],
      'serverTime': _iso(DateTime.now()),
    };
  }

  static Object? _decide(MockRequest request, {required bool approve}) {
    final group = _requireManaged(request);
    final approval = group.approvals
        .where((approval) => approval.id == request.params['approvalId'] && approval.isOpen)
        .firstOrNull;
    if (approval == null) throw const MockFailure(404, 'Someone already answered that.', code: 'approval_not_found');
    approval.status = approve ? 'approved' : 'declined';
    return {'id': approval.id, 'status': approval.status};
  }

  static MockApproval? _approvalById(String id) {
    for (final group in _groups.values) {
      for (final approval in group.approvals) {
        if (approval.id == id) return approval;
      }
    }
    return null;
  }

  static Object? _approvalStatus(MockRequest request) {
    final approval = _approvalById(request.params['id']!);
    if (approval == null) throw const MockFailure(404, 'We can’t find that request.', code: 'approval_not_found');
    _settleAutomatic(approval);
    return {'id': approval.id, 'status': approval.status, 'serverTime': _iso(DateTime.now())};
  }

  static Map<String, dynamic>? _rideFor(Map<String, dynamic> body) {
    final rideFor = body['rideFor'];
    if (rideFor is! Map || rideFor['groupId'] == null) return null;
    return Map<String, dynamic>.from(rideFor);
  }

  static Map<String, dynamic>? _subjectOf(MockGroup group, Map<String, dynamic> rideFor) {
    final memberId = rideFor['type'] == 'business' ? _meId : rideFor['memberId'] as String?;
    return group.memberById(memberId);
  }

  static void guardRide(Map<String, dynamic> body) {
    if (body['delivery'] != null) return;
    final rideFor = _rideFor(body);
    final group = rideFor == null ? null : _groups[rideFor['groupId']];
    if (rideFor == null || group == null || !_mine.contains(group.id)) return;
    if (_myRole(group).isManager) return;
    final subject = _subjectOf(group, rideFor);
    final me = group.memberById(_meId)!;
    final permissions = (subject?['permissions'] as Map?) ?? const {};
    final isForOther = subject != null && subject['id'] != _meId;
    final myPermissions = (me['permissions'] as Map?) ?? const {};
    if (subject == null || permissions['bookRides'] != true || (isForOther && myPermissions['bookForOthers'] != true)) {
      throw const MockFailure(403, 'Group rides are switched off.', code: 'group_rides_not_allowed');
    }
    final limits = Map<String, dynamic>.from(subject['limits'] as Map);
    _guardRideType(limits, body);
    _guardTime(limits);
    _guardPlace(limits, body);
    final key = '${group.id}:${subject['id']}';
    final perDay = (limits['ridesPerDay'] as num?)?.toInt();
    if (perDay != null && (_requestsToday[key] ?? 0) >= perDay) {
      throw const MockFailure(403, 'That’s all the group rides for today.', code: 'daily_ride_limit');
    }
    _guardSpend(group, subject, limits, body, rideFor);
    _requestsToday[key] = (_requestsToday[key] ?? 0) + 1;
  }

  static void _guardRideType(Map<String, dynamic> limits, Map<String, dynamic> body) {
    final types = limits['rideTypes'];
    final option = body['optionId'];
    if (types is List && option != null && !types.contains(option)) {
      throw const MockFailure(403, 'That ride type isn’t allowed.', code: 'ride_type_not_allowed');
    }
  }

  static void _guardTime(Map<String, dynamic> limits) {
    final window = limits['timeWindow'];
    if (window is! Map) return;
    int minutes(String value) {
      final parts = value.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    final from = minutes(window['from'] as String);
    final to = minutes(window['to'] as String);
    final isInside = from <= to ? current >= from && current <= to : current >= from || current <= to;
    if (!isInside) throw const MockFailure(403, 'Not at this time.', code: 'outside_time_window');
  }

  static void _guardPlace(Map<String, dynamic> limits, Map<String, dynamic> body) {
    final places = limits['approvedPlaces'];
    if (places is! List || places.isEmpty) return;
    final approved = {for (final place in places) ((place as Map)['place'] as Map)['place_id']};
    final pickup = (body['pickup'] as Map?)?['place_id'];
    final dropoff = (body['dropoff'] as Map?)?['place_id'];
    if (!approved.contains(pickup) && !approved.contains(dropoff)) {
      throw const MockFailure(403, 'That place isn’t on the list.', code: 'place_not_approved');
    }
  }

  static void _guardSpend(
    MockGroup group,
    Map<String, dynamic> subject,
    Map<String, dynamic> limits,
    Map<String, dynamic> body,
    Map<String, dynamic> rideFor,
  ) {
    final approvalId = body['approvalId'] as String?;
    if (approvalId != null) return _checkApproval(approvalId);
    final cap = (limits['monthlySpend'] as num?)?.toInt();
    final fare = (body['proposedFare'] as num?)?.toInt() ?? 0;
    final spent = (subject['monthSpent'] as num?)?.toInt() ?? 0;
    if (cap == null || spent + fare <= cap) return;
    switch (limits['overLimit']) {
      case 'block':
        throw const MockFailure(403, 'That’s over the monthly limit.', code: 'spending_limit_reached');
      case 'ask_approval':
        final approval = MockApproval(
          id: _nextId('apr'),
          memberId: subject['id'] as String,
          memberName: subject['name'] as String,
          fare: fare,
          pickup: Map<String, dynamic>.from((body['pickup'] as Map?) ?? const {'name': 'Pickup'}),
          dropoff: Map<String, dynamic>.from((body['dropoff'] as Map?) ?? const {'name': 'Drop off'}),
          purpose: rideFor['purpose'] as String?,
          requestedAt: DateTime.now(),
          decideAt: DateTime.now().add(
            '${rideFor['purpose']}'.toLowerCase().contains('decline') ? _autoDeclineAfter : _autoApproveAfter,
          ),
          declineAutomatically: '${rideFor['purpose']}'.toLowerCase().contains('decline'),
        );
        group.approvals.add(approval);
        throw MockFailure(
          409,
          'An admin needs to say yes first.',
          code: 'requires_approval',
          data: {'approvalId': approval.id},
        );
    }
  }

  static void _checkApproval(String approvalId) {
    final approval = _approvalById(approvalId);
    if (approval == null) return;
    _settleAutomatic(approval);
    if (approval.status == 'declined') {
      throw const MockFailure(403, 'An admin said no to this ride.', code: 'approval_declined');
    }
    if (approval.status == 'expired') {
      throw const MockFailure(403, 'The request ran out of time.', code: 'approval_expired');
    }
  }

  static Map<String, dynamic>? paymentGroup(Map<String, dynamic>? rideFor) {
    final groupId = rideFor?['groupId'];
    final group = _groups[groupId];
    if (group == null) return null;
    return {'id': group.id, 'kind': group.kind, 'name': group.name};
  }

  static bool canPayWithGroupWallet(Map<String, dynamic>? rideFor, int fare) {
    final group = _groups[rideFor?['groupId']];
    if (rideFor == null || group == null || !_mine.contains(group.id)) return false;
    if (_myRole(group).isManager) return true;
    final subject = _subjectOf(group, rideFor);
    if (subject == null || (subject['permissions'] as Map)['useGroupWallet'] != true) return false;
    final limits = subject['limits'] as Map;
    final cap = (limits['monthlySpend'] as num?)?.toInt();
    final spent = (subject['monthSpent'] as num?)?.toInt() ?? 0;
    return cap == null || spent + fare <= cap || limits['overLimit'] == 'ask_approval';
  }

  static ({String id, String? memberName})? paymentTarget(Map<String, dynamic>? rideFor) {
    final group = _groups[rideFor?['groupId']];
    if (rideFor == null || group == null) return null;
    final subject = _subjectOf(group, rideFor);
    return (id: group.id, memberName: subject?['name'] as String?);
  }

  static void recordSpend(Map<String, dynamic>? rideFor, int fare) {
    final group = _groups[rideFor?['groupId']];
    if (rideFor == null || group == null) return;
    final subject = _subjectOf(group, rideFor);
    if (subject == null) return;
    subject['monthSpent'] = ((subject['monthSpent'] as num?)?.toInt() ?? 0) + fare;
  }

  static Map<String, dynamic>? pendingApprovalNotice() {
    for (final id in _mine) {
      final group = _groups[id]!;
      if (!_myRole(group).isManager) continue;
      final approval = group.approvals.where((approval) => approval.isOpen).firstOrNull;
      if (approval == null) continue;
      return {
        'groupId': group.id,
        'memberName': approval.memberName,
        'fare': approval.fare,
        'at': approval.requestedAt,
      };
    }
    return null;
  }
}

class _Role {
  const _Role(this.code);

  final String? code;

  bool get isOwner => code == 'owner';

  bool get isManager => code == 'owner' || code == 'admin';
}
