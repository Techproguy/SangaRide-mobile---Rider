import 'package:sanga_ride_core/sanga_ride_core.dart';

class IdDocumentType {
  const IdDocumentType({required this.code, required this.label, required this.hasBack, this.hint});

  factory IdDocumentType.fromReader(JsonReader reader) => IdDocumentType(
    code: reader.strOrNull('code') ?? reader.str('id'),
    label: reader.str('label'),
    hasBack: reader.boolOr('hasBack', (reader.intOrNull('sides') ?? 1) > 1),
    hint: reader.strOrNull('hint'),
  );

  final String code;
  final String label;
  final bool hasBack;
  final String? hint;

  String get frontLabel => hasBack ? 'Front of ID' : 'Photo page';

  @override
  bool operator ==(Object other) => other is IdDocumentType && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
