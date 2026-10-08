enum RideForKind {
  me('Just for me', null),
  family('Family member', 'Book it for someone in your family'),
  someone('Someone else', 'Send a ride to another person'),
  business('Business ride', 'Trips for your company');

  const RideForKind(this.label, this.description);

  final String label;
  final String? description;
}

enum PassengerGender {
  male('male', 'Male'),
  female('female', 'Female');

  const PassengerGender(this.code, this.label);

  final String code;
  final String label;

  static PassengerGender? fromCode(String? code) => values.where((gender) => gender.code == code).firstOrNull;
}

enum PassengerFailure {
  otpMismatch('otp_mismatch', 'That code didn’t match. Give it another go.', needsNewCode: false),
  otpExpired('otp_expired', 'That code has expired. Grab a new one below.', needsNewCode: true),
  tooManyAttempts('too_many_attempts', 'Too many wrong tries. Grab a new code below.', needsNewCode: true),
  verificationNotFound(
    'verification_not_found',
    'We lost track of that code. Grab a new one below.',
    needsNewCode: true,
  ),
  ownNumber('own_number', 'That’s your own number. Pick Just for me instead.', needsNewCode: false),
  invalidPhone('invalid_phone', 'We can’t text that number. Check it and try again.', needsNewCode: false),
  connection('connection', 'We couldn’t reach the server. Give it another go.', needsNewCode: false);

  const PassengerFailure(this.code, this.message, {required this.needsNewCode});

  final String code;
  final String message;
  final bool needsNewCode;

  static PassengerFailure fromCode(String? code) =>
      values.firstWhere((failure) => failure.code == code, orElse: () => connection);

  String messageWith({int? attemptsLeft}) {
    if (this != otpMismatch || attemptsLeft == null) return message;
    final tries = attemptsLeft == 1 ? '1 try left' : '$attemptsLeft tries left';
    return 'That code didn’t match. $tries.';
  }
}

DateTime _localDeadline(Map<String, dynamic> json, String key) {
  final deadline = DateTime.parse(json[key] as String);
  final serverTime = DateTime.parse(json['serverTime'] as String);
  return DateTime.now().add(deadline.difference(serverTime));
}

class PassengerInfo {
  const PassengerInfo({required this.name, required this.phone, this.email, this.gender});

  final String name;
  final String phone;
  final String? email;
  final PassengerGender? gender;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'email': ?email, 'gender': ?gender?.code};
}

class PassengerVerification {
  const PassengerVerification({required this.id, required this.expiresAt, required this.sentAt});

  factory PassengerVerification.fromJson(Map<String, dynamic> json) => PassengerVerification(
    id: json['verificationId'] as String,
    expiresAt: _localDeadline(json, 'expiresAt'),
    sentAt: DateTime.now(),
  );

  final String id;
  final DateTime expiresAt;
  final DateTime sentAt;
}

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    required this.needsApproval,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    name: json['name'] as String,
    relationship: json['relationship'] as String,
    phone: json['phone'] as String,
    needsApproval: json['needsApproval'] as bool,
  );

  final String id;
  final String name;
  final String relationship;
  final String phone;
  final bool needsApproval;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}

class BusinessProfile {
  const BusinessProfile({
    required this.id,
    required this.companyName,
    required this.role,
    required this.purposes,
    required this.requiresCostCentre,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
    id: json['id'] as String,
    companyName: json['companyName'] as String,
    role: json['role'] as String,
    purposes: [for (final purpose in json['purposes'] as List) purpose as String],
    requiresCostCentre: json['costCentreRequired'] as bool,
  );

  final String id;
  final String companyName;
  final String role;
  final List<String> purposes;
  final bool requiresCostCentre;
}

sealed class RideFor {
  const RideFor();

  RideForKind get kind;

  String get summary;

  String? get detail;

  Map<String, dynamic> toJson();
}

final class RideForMe extends RideFor {
  const RideForMe();

  @override
  RideForKind get kind => RideForKind.me;

  @override
  String get summary => 'Just you';

  @override
  String? get detail => null;

  @override
  Map<String, dynamic> toJson() => {'type': 'me'};
}

final class RideForSomeone extends RideFor {
  const RideForSomeone({required this.passenger, required this.verifiedAt});

  final PassengerInfo passenger;
  final DateTime verifiedAt;

  @override
  RideForKind get kind => RideForKind.someone;

  @override
  String get summary => passenger.name;

  @override
  String? get detail => 'Number checked';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'someone',
    'passenger': passenger.toJson(),
    'verifiedAt': verifiedAt.toUtc().toIso8601String(),
  };
}

final class RideForFamily extends RideFor {
  const RideForFamily({required this.member});

  final FamilyMember member;

  @override
  RideForKind get kind => RideForKind.family;

  @override
  String get summary => member.name;

  @override
  String? get detail => member.relationship;

  @override
  Map<String, dynamic> toJson() => {'type': 'family', 'memberId': member.id, 'needsApproval': member.needsApproval};
}

final class RideForBusiness extends RideFor {
  const RideForBusiness({required this.profile, required this.purpose, this.costCentre, this.note});

  final BusinessProfile profile;
  final String purpose;
  final String? costCentre;
  final String? note;

  @override
  RideForKind get kind => RideForKind.business;

  @override
  String get summary => profile.companyName;

  @override
  String? get detail => purpose;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'business',
    'profileId': profile.id,
    'purpose': purpose,
    'costCentre': ?costCentre,
    'note': ?note,
  };
}

sealed class RideForListState<T> {
  const RideForListState();
}

final class RideForListLoading<T> extends RideForListState<T> {
  const RideForListLoading();
}

final class RideForListFailed<T> extends RideForListState<T> {
  const RideForListFailed();
}

final class RideForListLoaded<T> extends RideForListState<T> {
  const RideForListLoaded(this.items);

  final List<T> items;
}

sealed class PassengerFlowState {
  const PassengerFlowState();
}

final class PassengerIdle extends PassengerFlowState {
  const PassengerIdle();
}

final class PassengerSending extends PassengerFlowState {
  const PassengerSending();
}

final class PassengerSendFailed extends PassengerFlowState {
  const PassengerSendFailed(this.failure);

  final PassengerFailure failure;
}

final class PassengerCodePending extends PassengerFlowState {
  const PassengerCodePending({
    required this.info,
    required this.verification,
    this.failure,
    this.attemptsLeft,
    this.isResending = false,
  });

  final PassengerInfo info;
  final PassengerVerification verification;
  final PassengerFailure? failure;
  final int? attemptsLeft;
  final bool isResending;

  String? get errorText => failure?.messageWith(attemptsLeft: attemptsLeft);

  bool get needsNewCode => failure?.needsNewCode ?? false;
}

final class PassengerChecking extends PassengerFlowState {
  const PassengerChecking({required this.info, required this.verification});

  final PassengerInfo info;
  final PassengerVerification verification;
}

final class PassengerVerified extends PassengerFlowState {
  const PassengerVerified({required this.rideFor, required this.verification});

  final RideForSomeone rideFor;
  final PassengerVerification verification;
}
