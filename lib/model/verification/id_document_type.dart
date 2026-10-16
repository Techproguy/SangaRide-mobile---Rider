import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum IdDocumentType {
  nationalId('national_id', 'National identity card', 'Front and back of your card', hasBack: true),
  driversLicense('drivers_license', 'Driver’s license', 'Front and back of your license', hasBack: true),
  passport('passport', 'International passport', 'The page with your photo', hasBack: false);

  const IdDocumentType(this.code, this._label, this.hint, {required this.hasBack});

  final String code;
  final String _label;
  final String hint;
  final bool hasBack;

  String get label => switch ((this, SangaRegion.current)) {
    (nationalId, SangaRegion.us) => 'State ID card',
    (passport, SangaRegion.us) => 'Passport',
    _ => _label,
  };

  String get frontLabel => hasBack ? 'Front of ID' : 'Photo page';

  static IdDocumentType? fromCode(Object? code) => values.where((type) => type.code == '$code').firstOrNull;
}
