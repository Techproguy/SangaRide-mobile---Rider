enum VerificationStatus {
  unverified('unverified'),
  pending('pending'),
  verified('verified'),
  rejected('rejected'),
  actionNeeded('action_needed');

  const VerificationStatus(this.code);

  final String code;

  bool get needsAction => this == rejected || this == actionNeeded;

  static VerificationStatus fromCode(Object? code) =>
      values.where((status) => status.code == '$code').firstOrNull ?? unverified;
}
