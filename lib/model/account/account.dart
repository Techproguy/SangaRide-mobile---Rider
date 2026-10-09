import 'package:sanga_ride/model/user_model.dart';
import 'package:sanga_ride/model/verification/verification_status.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class Account {
  const Account({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.photoUrl,
    required this.rating,
    required this.ridesCount,
    required this.memberSince,
    required this.verification,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return Account(
      id: reader.str('id'),
      firstName: reader.strOr('firstName', ''),
      lastName: reader.strOr('lastName', ''),
      phone: reader.str('phone'),
      email: reader.strOrNull('email'),
      dateOfBirth: _dayOf(reader.strOrNull('dateOfBirth')),
      photoUrl: reader.strOrNull('photoUrl'),
      rating: reader.doubleOrNull('rating'),
      ridesCount: reader.intOr('ridesCount', 0),
      memberSince: reader.timeOrNull('memberSince')?.toLocal(),
      verification: VerificationStatus.fromCode(reader.objectOrNull('verification')?.strOrNull('status')),
    );
  }

  static DateTime? _dayOf(String? raw) => raw == null ? null : DateTime.tryParse(raw);

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final DateTime? dateOfBirth;
  final String? photoUrl;
  final double? rating;
  final int ridesCount;
  final DateTime? memberSince;
  final VerificationStatus verification;

  String get fullName => [firstName, lastName].where((part) => part.isNotEmpty).join(' ');

  UserModel toUserModel() => UserModel(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    avatarUrl: photoUrl,
    rating: rating,
    tripCount: ridesCount,
  );
}
