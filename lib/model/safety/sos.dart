import 'package:sanga_ride_core/sanga_ride_core.dart';

enum SafetyTeamStatus {
  alerted('alerted'),
  monitoring('monitoring');

  const SafetyTeamStatus(this.code);

  final String code;

  static SafetyTeamStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, alerted);
}

enum SosStatus {
  active('active'),
  ended('ended');

  const SosStatus(this.code);

  final String code;

  static SosStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, active);
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
    final reader = JsonReader.of(json);
    final sharing = reader.objectOrNull('locationSharing');
    final contacts = reader.objectOrNull('contactsNotified');
    final team = reader.objectOrNull('safetyTeam');
    return Sos(
      id: reader.str('id'),
      status: SosStatus.fromCode(reader.strOrNull('status')),
      startedAt: reader.timeOrNull('activatedAt') ?? reader.timeOrNull('startedAt') ?? reader.time('createdAt'),
      serverOffset: ServerClock.instance.now().difference(DateTime.now().toUtc()),
      liveLocation: sharing?.boolOr('active', false) ?? reader.boolOr('liveLocation', false),
      contactsNotified: contacts?.intOr('count', 0) ?? reader.intOr('contactsNotified', 0),
      safetyTeam: SafetyTeamStatus.fromCode(team?.strOrNull('status') ?? reader.strOrNull('safetyTeam')),
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
