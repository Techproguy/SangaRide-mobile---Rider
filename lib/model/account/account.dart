import 'package:sanga_ride/model/user_model.dart';
import 'package:sanga_ride/model/verification/verification_status.dart';

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

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    phone: json['phone'] as String,
    email: json['email'] as String?,
    dateOfBirth: json['dateOfBirth'] == null ? null : DateTime.parse('${json['dateOfBirth']}'),
    photoUrl: json['photoUrl'] as String?,
    rating: (json['rating'] as num?)?.toDouble(),
    ridesCount: (json['ridesCount'] as num?)?.toInt() ?? 0,
    memberSince: json['memberSince'] == null ? null : DateTime.parse('${json['memberSince']}').toLocal(),
    verification: VerificationStatus.fromCode((json['verification'] as Map?)?['status']),
  );

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
