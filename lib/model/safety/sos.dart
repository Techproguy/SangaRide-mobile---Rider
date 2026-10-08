enum SafetyTeamStatus {
  alerted('alerted'),
  monitoring('monitoring');

  const SafetyTeamStatus(this.code);

  final String code;

  static SafetyTeamStatus fromCode(String? code) =>
      values.firstWhere((status) => status.code == code, orElse: () => alerted);
}

enum SosStatus {
  active('active'),
  ended('ended');

  const SosStatus(this.code);

  final String code;

  static SosStatus fromCode(String? code) => values.firstWhere((status) => status.code == code, orElse: () => active);
}

class Sos {
  const Sos({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.serverOffset,
    required this.liveLocation,
    required this.contactsNotified,
    required this.safetyTeam,
  });

  factory Sos.fromJson(Map<String, dynamic> json) {
    final serverTime = DateTime.parse(json['serverTime'] as String);
    return Sos(
      id: json['id'] as String,
      status: SosStatus.fromCode(json['status'] as String?),
      startedAt: DateTime.parse(json['startedAt'] as String),
      serverOffset: serverTime.difference(DateTime.now()),
      liveLocation: json['liveLocation'] as bool? ?? false,
      contactsNotified: (json['contactsNotified'] as num?)?.toInt() ?? 0,
      safetyTeam: SafetyTeamStatus.fromCode(json['safetyTeam'] as String?),
    );
  }

  final String id;
  final SosStatus status;
  final DateTime startedAt;
  final Duration serverOffset;
  final bool liveLocation;
  final int contactsNotified;
  final SafetyTeamStatus safetyTeam;

  bool get isEnded => status == SosStatus.ended;

  bool get hasNotifiedContacts => contactsNotified > 0;
}
