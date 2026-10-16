import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class EmergencyContact {
  const EmergencyContact({required this.id, required this.name, required this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return EmergencyContact(id: reader.str('id'), name: reader.str('name'), phone: reader.str('phone'));
  }

  static List<EmergencyContact> listFromBody(Object? body) {
    final envelope = JsonReader.of(body);
    return JsonReader.of({'contacts': envelope.raw['data']}).listOf(
      'contacts',
      (contact) => EmergencyContact.fromJson(contact.raw),
    );
  }

  final String id;
  final String name;
  final String phone;

  String get displayPhone => SangaPhoneNumber.international(phone);
}
