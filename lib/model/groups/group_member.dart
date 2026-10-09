import 'package:sanga_ride/model/groups/group_kind.dart';

import 'dart:convert';

import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class MemberPermissions {
  const MemberPermissions({required this.bookRides, required this.bookForOthers, required this.useGroupWallet});

  factory MemberPermissions.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return MemberPermissions(
      bookRides: reader.boolOr('bookRides', true),
      bookForOthers: reader.boolOr('bookForOthers', false),
      useGroupWallet: reader.boolOr('useGroupWallet', true),
    );
  }

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

  factory MemberAlerts.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return MemberAlerts(
      tripStarted: reader.boolOr('tripStarted', true),
      tripEnded: reader.boolOr('tripEnded', true),
      sos: reader.boolOr('sos', true),
      overLimit: reader.boolOr('overLimit', true),
    );
  }

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

  static TimeWindow? tryFromReader(JsonReader? reader) {
    final from = reader?.strOrNull('from');
    final to = reader?.strOrNull('to');
    if (from == null || to == null) return null;
    return TimeWindow(from: from, to: to);
  }

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

  factory ApprovedPlace.fromReader(JsonReader reader) => ApprovedPlace(
    id: reader.str('id'),
    label: reader.strOr('label', ''),
    place: Place.fromJson(reader.object('place').raw),
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
    final reader = JsonReader(json);
    return MemberLimits(
      monthlySpend: reader.intOrNull('monthlySpend'),
      overLimit: OverLimitAction.fromCode(reader.strOrNull('overLimit')),
      ridesPerDay: reader.intOrNull('ridesPerDay'),
      timeWindow: TimeWindow.tryFromReader(reader.objectOrNull('timeWindow')),
      rideTypes: reader.raw['rideTypes'] is List ? reader.strings('rideTypes') : null,
      approvedPlaces: reader.listOf('approvedPlaces', ApprovedPlace.fromReader),
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

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return GroupMember(
      id: reader.str('id'),
      name: reader.strOr('name', ''),
      phone: reader.strOr('phone', ''),
      photoUrl: reader.strOrNull('photoUrl'),
      relation: reader.strOr('relation', 'Member'),
      role: GroupRole.fromCode(reader.strOrNull('role')),
      status: MemberStatus.fromCode(reader.strOrNull('status')),
      permissions: MemberPermissions.fromJson(reader.objectOrNull('permissions')?.raw ?? const {}),
      limits: MemberLimits.fromJson(reader.objectOrNull('limits')?.raw ?? const {}),
      alerts: MemberAlerts.fromJson(reader.objectOrNull('alerts')?.raw ?? const {}),
      monthSpent: reader.intOr('monthSpent', 0),
    );
  }

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

  Map<String, dynamic> changesAgainst(GroupMember member) {
    return {
      if (role != null && role != member.role) 'role': role!.code,
      if (relation != null && relation != member.relation) 'relation': relation,
      if (permissions != null) ..._section('permissions', permissions!.toJson(), member.permissions.toJson()),
      if (limits != null) ..._section('limits', limits!.toJson(), member.limits.toJson()),
      if (alerts != null) ..._section('alerts', alerts!.toJson(), member.alerts.toJson()),
    };
  }

  static Map<String, dynamic> _section(String key, Map<String, dynamic> wanted, Map<String, dynamic> current) {
    final changed = {
      for (final entry in wanted.entries)
        if (jsonEncode(entry.value) != jsonEncode(current[entry.key])) entry.key: entry.value,
    };
    return changed.isEmpty ? const {} : {key: changed};
  }
}
