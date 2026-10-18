import 'package:sanga_ride/core/safety_config.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride/model/safety/emergency_contact.dart';
import 'package:sanga_ride/model/safety/sos.dart';

enum CounterpartRole {
  driver('driver', 'Driver'),
  rider('rider', 'Rider');

  const CounterpartRole(this.code, this.label);

  final String code;
  final String label;

  static CounterpartRole fromCode(String? code) => codedEnum(values, (role) => role.code, code, orElse: driver);
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

  factory SafetyTrip.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final driver = reader.objectOrNull('driver');
    final passenger = reader.objectOrNull('passenger') ?? reader.objectOrNull('rider');
    final role = reader.strOrNull('counterpartRole') ?? (driver == null && passenger != null ? 'rider' : 'driver');
    final person = role == 'rider' ? passenger : driver;
    return SafetyTrip(
      id: reader.str('id'),
      reference: reader.strOr('reference', ''),
      isLive: reader.boolOr('isLive', false),
      counterpartName: reader.strOrNull('counterpartName') ?? person?.strOr('name', '').trim() ?? '',
      counterpartRole: CounterpartRole.fromCode(role),
      vehicle: _vehicleOf(reader),
      pickup: _placeOf(reader, 'pickup'),
      dropoff: _placeOf(reader, 'dropoff'),
      currentArea: reader.strOrNull('currentArea'),
      startedAt: reader.timeOrNull('startedAt')?.toLocal(),
    );
  }

  static String _vehicleOf(JsonReader reader) {
    final vehicle = reader.objectOrNull('vehicle');
    if (vehicle == null) return reader.strOr('vehicle', '');
    final car = [vehicle.strOrNull('colour'), vehicle.strOrNull('make'), vehicle.strOrNull('model')].nonNulls.join(' ');
    return [if (car.isNotEmpty) car, ?vehicle.strOrNull('plateNumber')].join(' · ');
  }

  static String _placeOf(JsonReader reader, String key) {
    final place = reader.objectOrNull(key);
    if (place == null) return reader.strOr(key, '');
    final address = place.strOr('address', '');
    return (place.strOrNull('name') ?? address.split(',').first).trim();
  }

  final String id;
  final String reference;
  final bool isLive;
  final String counterpartName;
  final CounterpartRole counterpartRole;
  final String vehicle;
  final String pickup;
  final String dropoff;
  final String? currentArea;
  final DateTime? startedAt;
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
    final reader = JsonReader.of(json);
    final activeSos = reader.objectOrNull('activeSos');
    final trip = reader.objectOrNull('ride');
    return SafetyCentre(
      contacts: reader.listOf('emergencyContacts', (contact) => EmergencyContact.fromJson(contact.raw)),
      maxContacts: reader.intOr('maxContacts', defaultMaxContacts),
      sosGrace: Duration(seconds: reader.intOr('sosGraceSeconds', SafetyConfig.sosGrace.inSeconds)),
      emergencyNumber: SafetyConfig.numberOr(reader.strOrNull('emergencyNumber')),
      activeSos: activeSos == null ? null : _tryRead(() => Sos.fromJson(activeSos.raw)),
      trip: trip == null ? null : _tryRead(() => SafetyTrip.fromJson(trip.raw)),
    );
  }

  static const int defaultMaxContacts = 5;

  static T? _tryRead<T>(T Function() parse) {
    try {
      return parse();
    } catch (_) {
      return null;
    }
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
