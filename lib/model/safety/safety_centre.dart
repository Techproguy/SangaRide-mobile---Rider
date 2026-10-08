import 'package:sanga_ride/model/safety/emergency_contact.dart';
import 'package:sanga_ride/model/safety/sos.dart';

enum CounterpartRole {
  driver('driver', 'Driver'),
  rider('rider', 'Rider');

  const CounterpartRole(this.code, this.label);

  final String code;
  final String label;

  static CounterpartRole fromCode(String? code) => values.firstWhere((role) => role.code == code, orElse: () => driver);
}

class SafetyTrip {
  const SafetyTrip({
    required this.id,
    required this.reference,
    required this.isLive,
    required this.counterpartName,
    required this.counterpartRole,
    required this.vehicle,
    required this.pickup,
    required this.dropoff,
    required this.currentArea,
    required this.startedAt,
  });

  factory SafetyTrip.fromJson(Map<String, dynamic> json) => SafetyTrip(
    id: json['id'] as String,
    reference: json['reference'] as String,
    isLive: json['isLive'] as bool? ?? false,
    counterpartName: json['counterpartName'] as String,
    counterpartRole: CounterpartRole.fromCode(json['counterpartRole'] as String?),
    vehicle: json['vehicle'] as String,
    pickup: json['pickup'] as String,
    dropoff: json['dropoff'] as String,
    currentArea: json['currentArea'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String).toLocal(),
  );

  final String id;
  final String reference;
  final bool isLive;
  final String counterpartName;
  final CounterpartRole counterpartRole;
  final String vehicle;
  final String pickup;
  final String dropoff;
  final String? currentArea;
  final DateTime startedAt;
}

class SafetyCentre {
  const SafetyCentre({
    required this.contacts,
    required this.maxContacts,
    required this.sosGrace,
    required this.emergencyNumber,
    required this.activeSos,
    required this.trip,
  });

  factory SafetyCentre.fromJson(Map<String, dynamic> json) {
    final activeSos = json['activeSos'] as Map?;
    final trip = json['trip'] as Map?;
    return SafetyCentre(
      contacts: [
        for (final contact in json['contacts'] as List)
          EmergencyContact.fromJson(Map<String, dynamic>.from(contact as Map)),
      ],
      maxContacts: (json['maxContacts'] as num).toInt(),
      sosGrace: Duration(seconds: (json['sosGraceSeconds'] as num).toInt()),
      emergencyNumber: json['emergencyNumber'] as String,
      activeSos: activeSos == null
          ? null
          : Sos.fromJson({'serverTime': json['serverTime'], ...Map<String, dynamic>.from(activeSos)}),
      trip: trip == null ? null : SafetyTrip.fromJson(Map<String, dynamic>.from(trip)),
    );
  }

  final List<EmergencyContact> contacts;
  final int maxContacts;
  final Duration sosGrace;
  final String emergencyNumber;
  final Sos? activeSos;
  final SafetyTrip? trip;

  bool get canAddContact => contacts.length < maxContacts;

  SafetyCentre withContacts(List<EmergencyContact> contacts) => SafetyCentre(
    contacts: contacts,
    maxContacts: maxContacts,
    sosGrace: sosGrace,
    emergencyNumber: emergencyNumber,
    activeSos: activeSos,
    trip: trip,
  );
}
