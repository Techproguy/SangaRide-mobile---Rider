import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class EmergencyContact {
  const EmergencyContact({required this.id, required this.name, required this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(id: json['id'] as String, name: json['name'] as String, phone: json['phone'] as String);

  final String id;
  final String name;
  final String phone;

  String get displayPhone => '${SangaPhoneNumber.dialCode} ${SangaPhoneNumber.format(phone)}';
}
