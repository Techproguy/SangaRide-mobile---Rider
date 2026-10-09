import 'package:sanga_ride/model/groups/group_kind.dart';
import 'package:sanga_ride/model/location/place.dart';

class MemberPermissions {
  const MemberPermissions({required this.bookRides, required this.bookForOthers, required this.useGroupWallet});

  factory MemberPermissions.fromJson(Map<String, dynamic> json) => MemberPermissions(
    bookRides: json['bookRides'] as bool? ?? true,
    bookForOthers: json['bookForOthers'] as bool? ?? false,
    useGroupWallet: json['useGroupWallet'] as bool? ?? true,
  );

  final bool bookRides;
  final bool bookForOthers;
  final bool useGroupWallet;

  MemberPermissions copyWith({bool? bookRides, bool? bookForOthers, bool? useGroupWallet}) => MemberPermissions(
    bookRides: bookRides ?? this.bookRides,
    bookForOthers: bookForOthers ?? this.bookForOthers,
    useGroupWallet: useGroupWallet ?? this.useGroupWallet,
  );

  Map<String, dynamic> toJson() => {
    'bookRides': bookRides,
    'bookForOthers': bookForOthers,
    'useGroupWallet': useGroupWallet,
  };
}

class MemberAlerts {
  const MemberAlerts({required this.tripStarted, required this.tripEnded, required this.sos, required this.overLimit});

  factory MemberAlerts.fromJson(Map<String, dynamic> json) => MemberAlerts(
    tripStarted: json['tripStarted'] as bool? ?? true,
    tripEnded: json['tripEnded'] as bool? ?? true,
    sos: json['sos'] as bool? ?? true,
    overLimit: json['overLimit'] as bool? ?? true,
  );

  final bool tripStarted;
  final bool tripEnded;
  final bool sos;
  final bool overLimit;

  MemberAlerts copyWith({bool? tripStarted, bool? tripEnded, bool? sos, bool? overLimit}) => MemberAlerts(
    tripStarted: tripStarted ?? this.tripStarted,
    tripEnded: tripEnded ?? this.tripEnded,
    sos: sos ?? this.sos,
    overLimit: overLimit ?? this.overLimit,
  );

  Map<String, dynamic> toJson() => {
    'tripStarted': tripStarted,
    'tripEnded': tripEnded,
    'sos': sos,
    'overLimit': overLimit,
  };
}

class TimeWindow {
  const TimeWindow({required this.from, required this.to});

  factory TimeWindow.fromJson(Map<String, dynamic> json) =>
      TimeWindow(from: json['from'] as String, to: json['to'] as String);

  static String encode(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static (int, int) decode(String value) {
    final parts = value.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  final String from;
  final String to;

  Map<String, dynamic> toJson() => {'from': from, 'to': to};
}

class ApprovedPlace {
  const ApprovedPlace({required this.id, required this.label, required this.place});

  factory ApprovedPlace.fromJson(Map<String, dynamic> json) => ApprovedPlace(
    id: json['id'] as String,
    label: json['label'] as String,
    place: Place.fromJson(Map<String, dynamic>.from(json['place'] as Map)),
  );

  final String id;
  final String label;
  final Place place;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'place': place.toJson()};
}

class MemberLimits {
  const MemberLimits({
    required this.monthlySpend,
    required this.overLimit,
    required this.ridesPerDay,
    required this.timeWindow,
    required this.rideTypes,
    required this.approvedPlaces,
  });

  factory MemberLimits.fromJson(Map<String, dynamic> json) {
    final window = json['timeWindow'];
    final types = json['rideTypes'];
    return MemberLimits(
      monthlySpend: (json['monthlySpend'] as num?)?.toInt(),
      overLimit: OverLimitAction.fromCode(json['overLimit'] as String?),
      ridesPerDay: (json['ridesPerDay'] as num?)?.toInt(),
      timeWindow: window == null ? null : TimeWindow.fromJson(Map<String, dynamic>.from(window as Map)),
      rideTypes: types == null ? null : [for (final type in types as List) type as String],
      approvedPlaces: [
        for (final place in (json['approvedPlaces'] as List? ?? const []))
          ApprovedPlace.fromJson(Map<String, dynamic>.from(place as Map)),
      ],
    );
  }

  final int? monthlySpend;
  final OverLimitAction overLimit;
  final int? ridesPerDay;
  final TimeWindow? timeWindow;
  final List<String>? rideTypes;
  final List<ApprovedPlace> approvedPlaces;

  MemberLimits copyWith({
    int? Function()? monthlySpend,
    OverLimitAction? overLimit,
    int? Function()? ridesPerDay,
    TimeWindow? Function()? timeWindow,
    List<String>? Function()? rideTypes,
    List<ApprovedPlace>? approvedPlaces,
  }) => MemberLimits(
    monthlySpend: monthlySpend == null ? this.monthlySpend : monthlySpend(),
    overLimit: overLimit ?? this.overLimit,
    ridesPerDay: ridesPerDay == null ? this.ridesPerDay : ridesPerDay(),
    timeWindow: timeWindow == null ? this.timeWindow : timeWindow(),
    rideTypes: rideTypes == null ? this.rideTypes : rideTypes(),
    approvedPlaces: approvedPlaces ?? this.approvedPlaces,
  );

  Map<String, dynamic> toJson() => {
    'monthlySpend': monthlySpend,
    'overLimit': overLimit.code,
    'ridesPerDay': ridesPerDay,
    'timeWindow': timeWindow?.toJson(),
    'rideTypes': rideTypes,
    'approvedPlaces': [for (final place in approvedPlaces) place.toJson()],
  };
}

class GroupMember {
  const GroupMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.relation,
    required this.role,
    required this.status,
    required this.permissions,
    required this.limits,
    required this.alerts,
    required this.monthSpent,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    photoUrl: json['photoUrl'] as String?,
    relation: json['relation'] as String,
    role: GroupRole.fromCode(json['role'] as String?),
    status: MemberStatus.fromCode(json['status'] as String?),
    permissions: MemberPermissions.fromJson(Map<String, dynamic>.from(json['permissions'] as Map)),
    limits: MemberLimits.fromJson(Map<String, dynamic>.from(json['limits'] as Map)),
    alerts: MemberAlerts.fromJson(Map<String, dynamic>.from(json['alerts'] as Map)),
    monthSpent: (json['monthSpent'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final String relation;
  final GroupRole role;
  final MemberStatus status;
  final MemberPermissions permissions;
  final MemberLimits limits;
  final MemberAlerts alerts;
  final int monthSpent;

  bool get isInvited => status == MemberStatus.invited;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get caption => isInvited ? '$relation · Invited' : relation;
}

class MemberPatch {
  const MemberPatch({this.role, this.relation, this.permissions, this.limits, this.alerts});

  final GroupRole? role;
  final String? relation;
  final MemberPermissions? permissions;
  final MemberLimits? limits;
  final MemberAlerts? alerts;

  Map<String, dynamic> toJson() => {
    'role': ?role?.code,
    'relation': ?relation,
    'permissions': ?permissions?.toJson(),
    'limits': ?limits?.toJson(),
    'alerts': ?alerts?.toJson(),
  };
}
