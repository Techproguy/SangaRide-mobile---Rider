import 'package:sanga_ride/model/user_model.dart';
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
      dateOfBirth: _dayOf(reader.strOrNull('birthday')),
      photoUrl: reader.strOrNull('avatarUrl'),
      rating: reader.doubleOrNull('rating'),
      ridesCount: reader.intOr('ridesCount', 0),
      memberSince: reader.timeOrNull('createdAt')?.toLocal(),
      verification: _verificationOf(reader.objectOrNull('verification')),
    );
  }

  static VerificationStatus _verificationOf(JsonReader? json) {
    if (json == null) return VerificationStatus.unverified;
    if (json.boolOr('isVerified', false)) return VerificationStatus.verified;
    final parts = [
      VerificationStatus.fromCode(json.objectOrNull('selfie')?.strOrNull('status')),
      VerificationStatus.fromCode(json.objectOrNull('documents')?.strOrNull('status')),
    ];
    if (parts.any((part) => part.needsAction)) return VerificationStatus.rejected;
    if (parts.every((part) => part == VerificationStatus.pending || part == VerificationStatus.verified)) {
      return VerificationStatus.pending;
    }
    return VerificationStatus.unverified;
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
