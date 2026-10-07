class UserModel {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final double? rating;
  final int tripCount;

  const UserModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.rating,
    this.tripCount = 0,
  });

  String get displayName => [firstName, lastName].whereType<String>().where((s) => s.isNotEmpty).join(' ');

  bool get isProfileComplete => (firstName ?? '').isNotEmpty && (lastName ?? '').isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    rating: (json['rating'] as num?)?.toDouble(),
    tripCount: json['tripCount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'rating': rating,
    'tripCount': tripCount,
  };
}
