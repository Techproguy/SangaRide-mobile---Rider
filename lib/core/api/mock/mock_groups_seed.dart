import 'package:sanga_ride/core/api/mock/mock_data.dart';

class MockApproval {
  MockApproval({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.fare,
    required this.pickup,
    required this.dropoff,
    required this.requestedAt,
    this.purpose,
    this.decideAt,
    this.declineAutomatically = false,
    this.cancelAt,
    DateTime? expiresAt,
  }) : expiresAt = expiresAt ?? requestedAt.add(lifetime);

  static const Duration lifetime = Duration(minutes: 30);

  final String id;
  final String memberId;
  final String memberName;
  final int fare;
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final DateTime requestedAt;
  final String? purpose;
  final DateTime? decideAt;
  final bool declineAutomatically;
  final DateTime? cancelAt;
  final DateTime expiresAt;
  String status = 'pending';

  bool get isOpen => status == 'pending';

  void sync(DateTime now) {
    if (status != 'pending') return;
    final cancel = cancelAt;
    if (cancel != null && !now.isBefore(cancel)) {
      status = 'cancelled';
    } else if (!now.isBefore(expiresAt)) {
      status = 'expired';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'memberName': memberName,
    'fare': fare,
    'pickup': {'name': pickup['name'], 'address': pickup['address'] ?? pickup['name']},
    'dropoff': {'name': dropoff['name'], 'address': dropoff['address'] ?? dropoff['name']},
    'purpose': purpose,
    'requestedAt': requestedAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'status': status,
  };
}

class MockGroup {
  MockGroup({
    required this.id,
    required this.kind,
    required this.name,
    required this.inviteCode,
    required this.members,
    this.company,
    List<MockApproval>? approvals,
  }) : approvals = approvals ?? [];

  final String id;
  final String kind;
  final String name;
  final String inviteCode;
  final Map<String, dynamic>? company;
  final List<Map<String, dynamic>> members;
  final List<MockApproval> approvals;

  List<Map<String, dynamic>> get activeMembers => [
    for (final member in members)
      if (member['status'] == 'active') member,
  ];

  int get activeCount => activeMembers.length;

  Map<String, dynamic>? memberById(Object? memberId) {
    for (final member in members) {
      if (member['id'] == memberId) return member;
    }
    return null;
  }

  Map<String, dynamic> memberJson(Map<String, dynamic> member) => {
    ...member,
    'permissions': Map<String, dynamic>.of(member['permissions'] as Map<String, dynamic>),
    'limits': Map<String, dynamic>.of(member['limits'] as Map<String, dynamic>),
    'alerts': Map<String, dynamic>.of(member['alerts'] as Map<String, dynamic>),
  };
}

abstract final class MockGroupsSeed {
  static const String johnsonsId = 'grp_johnsons';
  static const String rayId = 'grp_ray';
  static const String kudiId = 'grp_kudi';
  static const String rayCode = 'JOIN2026';

  static const List<String> purposes = ['Client meeting', 'Airport run', 'Site visit', 'Team lunch', 'Office commute'];

  static const Map<String, Map<String, dynamic>> _places = {
    'maryland': {
      'place_id': 'mock_maryland',
      'name': 'Maryland College',
      'address': 'Iyana Ipaja, Lagos',
      'coordinates': {'lat': 6.6126, 'lng': 3.2873},
    },
    'palms': {
      'place_id': 'mock_palms',
      'name': 'The Palms Mall',
      'address': 'Lekki Phase 1, Lagos',
      'coordinates': {'lat': 6.4352, 'lng': 3.4515},
    },
    'home': {
      'place_id': 'mock_cr_ikeja',
      'name': 'Chicken Republic',
      'address': 'Allen Avenue, Ikeja, Lagos',
      'coordinates': {'lat': 6.6018, 'lng': 3.3515},
    },
  };

  static String relationOf(String kind, String? role) => switch ((kind, role)) {
    ('family', 'parent') => 'Parent',
    ('family', 'guardian') => 'Guardian',
    ('family', 'spouse') => 'Spouse',
    ('family', _) => 'Family',
    ('business', 'owner') => 'Owner',
    ('business', 'manager') => 'Manager',
    _ => 'Team member',
  };

  static Map<String, dynamic> member({
    required String id,
    required String name,
    required String phone,
    required String relation,
    String role = 'member',
    String status = 'active',
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? limits,
    int monthSpent = 0,
  }) => {
    'id': id,
    'name': name,
    'phone': phone,
    'photoUrl': null,
    'relation': relation,
    'role': role,
    'status': status,
    'permissions': {'bookRides': true, 'bookForOthers': false, 'useGroupWallet': true, ...?permissions},
    'limits': {
      'monthlySpend': null,
      'overLimit': 'block',
      'ridesPerDay': null,
      'timeWindow': null,
      'rideTypes': null,
      'approvedPlaces': <Map<String, dynamic>>[],
      ...?limits,
    },
    'alerts': {'tripStarted': true, 'tripEnded': true, 'sos': true, 'overLimit': true},
    'monthSpent': monthSpent,
  };

  static Map<String, dynamic> me({required String role, required String relation, String forKind = 'family'}) {
    final isBusinessMember = forKind == 'business' && role == 'member';
    return member(
      id: MockData.user['id'] as String,
      name: '${MockData.user['firstName']} ${MockData.user['lastName']}',
      phone: MockData.user['phone'] as String,
      relation: relation,
      role: role,
      permissions: role == 'owner' ? {'bookForOthers': true} : null,
      limits: isBusinessMember
          ? {
              'monthlySpend': 40000,
              'overLimit': 'ask_approval',
              'ridesPerDay': 4,
              'timeWindow': {'from': '07:00', 'to': '22:00'},
              'rideTypes': ['go', 'plus'],
            }
          : null,
      monthSpent: isBusinessMember ? 36500 : 0,
    );
  }

  static Map<String, dynamic> _place(String key) => {
    'id': 'ap_$key',
    'label': _places[key]!['name'],
    'place': Map<String, dynamic>.of(_places[key]!),
  };

  static MockGroup johnsons() {
    final group = MockGroup(
      id: johnsonsId,
      kind: 'family',
      name: 'The Johnsons',
      inviteCode: 'JOHN2026',
      members: [
        me(role: 'owner', relation: 'Parent'),
        member(
          id: 'mem_chidi',
          name: 'Chidi Johnson',
          phone: '+2348052223344',
          relation: 'Spouse',
          role: 'admin',
          permissions: {'bookForOthers': true},
        ),
        member(
          id: 'mem_tomi',
          name: 'Tomi Johnson',
          phone: '+2348031112233',
          relation: 'Son',
          limits: {
            'monthlySpend': 50000,
            'overLimit': 'ask_approval',
            'ridesPerDay': 3,
            'timeWindow': {'from': '06:00', 'to': '21:00'},
            'rideTypes': ['go', 'plus'],
            'approvedPlaces': [_place('maryland'), _place('palms')],
          },
          monthSpent: 48200,
        ),
        member(
          id: 'mem_tife',
          name: 'Tife Johnson',
          phone: '+2348064445566',
          relation: 'Daughter',
          limits: {
            'monthlySpend': 30000,
            'overLimit': 'block',
            'ridesPerDay': 2,
            'rideTypes': ['go'],
          },
          monthSpent: 8800,
        ),
        member(id: 'mem_mama', name: '0706 333 4455', phone: '+2347063334455', relation: 'Mother', status: 'invited'),
      ],
    );
    group.approvals.add(
      MockApproval(
        id: 'apr_seed_1',
        memberId: 'mem_tomi',
        memberName: 'Tomi Johnson',
        fare: 6500,
        pickup: _places['home']!,
        dropoff: _places['maryland']!,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    );
    group.approvals.add(
      MockApproval(
        id: 'apr_seed_2',
        memberId: 'mem_tife',
        memberName: 'Tife Johnson',
        fare: 4800,
        pickup: _places['maryland']!,
        dropoff: _places['home']!,
        requestedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        cancelAt: DateTime.now().add(const Duration(seconds: 40)),
      ),
    );
    return group;
  }

  static MockGroup ray() => MockGroup(
    id: rayId,
    kind: 'business',
    name: 'Ray Holdings Ltd',
    inviteCode: rayCode,
    company: {'rcNumber': 'RC 1482930', 'address': '14 Adeola Odeku Street, Victoria Island, Lagos'},
    members: [
      member(
        id: 'mem_ray',
        name: 'Raymond Okoye',
        phone: '+2348023334455',
        relation: 'Owner',
        role: 'owner',
        permissions: {'bookForOthers': true},
      ),
      member(
        id: 'mem_funke',
        name: 'Funke Adeyemi',
        phone: '+2348095556677',
        relation: 'Manager',
        role: 'admin',
        permissions: {'bookForOthers': true},
      ),
      member(
        id: 'mem_geo',
        name: 'Georgina Bello',
        phone: '+2348127778899',
        relation: 'Marketing',
        limits: {'monthlySpend': 60000, 'overLimit': 'ask_approval'},
        monthSpent: 21000,
      ),
    ],
  );

  static MockGroup kudi() => MockGroup(
    id: kudiId,
    kind: 'business',
    name: 'Kudi Ventures',
    inviteCode: 'KUDI2026',
    members: [
      member(
        id: 'mem_tunde',
        name: 'Tunde Bakare',
        phone: '+2348031230987',
        relation: 'Owner',
        role: 'owner',
        permissions: {'bookForOthers': true},
      ),
      member(
        id: 'mem_ngozi',
        name: 'Ngozi Eze',
        phone: '+2348076541234',
        relation: 'Operations',
        limits: {'monthlySpend': 40000, 'overLimit': 'block'},
        monthSpent: 12000,
      ),
    ],
  );

  static MockGroup? joinable(String code) => code == rayCode ? ray() : null;

  static MockGroup? byId(String id) => id == kudiId ? kudi() : (id == rayId ? ray() : null);

  static Map<String, dynamic> kudiInvite() => {
    'id': 'inv_kudi',
    'groupId': kudiId,
    'groupName': 'Kudi Ventures',
    'kind': 'business',
    'invitedBy': 'Tunde Bakare',
    'expiresAt': DateTime.now().add(const Duration(days: 3)).toUtc().toIso8601String(),
  };
}
