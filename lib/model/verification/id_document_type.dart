enum IdDocumentType {
  nationalId('national_id_card', 'National identity card', 'Front and back of your card', hasBack: true),
  driversLicense('drivers_license', 'Driver’s license', 'Front and back of your license', hasBack: true),
  votersCard('voters_card', 'Voter’s card', 'Front and back of your card', hasBack: true),
  passport('international_passport', 'International passport', 'The page with your photo', hasBack: false);

  const IdDocumentType(this.code, this.label, this.hint, {required this.hasBack});

  final String code;
  final String label;
  final String hint;
  final bool hasBack;

  String get frontLabel => hasBack ? 'Front of ID' : 'Photo page';

  static IdDocumentType? fromCode(Object? code) => values.where((type) => type.code == '$code').firstOrNull;
}
