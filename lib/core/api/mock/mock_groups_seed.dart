import 'package:sanga_ride/core/api/mock/mock_account.dart';
import 'package:sanga_ride/core/api/mock/mock_data.dart';
import 'package:sanga_ride/core/api/mock/mock_money.dart';
import 'package:sanga_ride/core/api/mock/mock_region.dart';

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
    'fare': MockMoney.json(fare),
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

  Map<String, dynamic> memberJson(Map<String, dynamic> member) {
    final limits = Map<String, dynamic>.of(member['limits'] as Map<String, dynamic>);
    return {
      ...member,
      'permissions': Map<String, dynamic>.of(member['permissions'] as Map<String, dynamic>),
      'limits': limits..['monthlySpend'] = MockMoney.jsonOrNull(limits['monthlySpend'] as num?),
      'alerts': Map<String, dynamic>.of(member['alerts'] as Map<String, dynamic>),
      'monthSpent': MockMoney.json(member['monthSpent'] as num),
    };
  }
}

abstract final class MockGroupsSeed {
  static const String rayId = 'grp_ray';
  static const String kudiId = 'grp_kudi';
  static const String rayCode = 'JOIN2026';

  static const List<String> purposes = ['Client meeting', 'Airport run', 'Site visit', 'Team lunch', 'Office commute'];

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
      name: '${MockAccount.firstName} ${MockAccount.lastName}',
      phone: MockAccount.phone,
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

  static MockGroup ray() => MockGroup(
    id: rayId,
    kind: 'business',
    name: 'Ray Holdings Ltd',
    inviteCode: rayCode,
    company: MockRegion.isUnitedStates
        ? {'rcNumber': 'EIN 84-1482930', 'address': '1400 Smith Street, Downtown, Houston, TX'}
        : {'rcNumber': 'RC 1482930', 'address': '14 Adeola Odeku Street, Victoria Island, Lagos'},
    members: [
      member(
        id: 'mem_ray',
        name: 'Raymond Okoye',
        phone: MockRegion.phone('8023334455'),
        relation: 'Owner',
        role: 'owner',
        permissions: {'bookForOthers': true},
      ),
      member(
        id: 'mem_funke',
        name: 'Funke Adeyemi',
        phone: MockRegion.phone('8095556677'),
        relation: 'Manager',
        role: 'admin',
        permissions: {'bookForOthers': true},
      ),
      member(
        id: 'mem_geo',
        name: 'Georgina Bello',
        phone: MockRegion.phone('8127778899'),
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
        phone: MockRegion.phone('8031230987'),
        relation: 'Owner',
        role: 'owner',
        permissions: {'bookForOthers': true},
      ),
      member(
        id: 'mem_ngozi',
        name: 'Ngozi Eze',
        phone: MockRegion.phone('8076541234'),
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
