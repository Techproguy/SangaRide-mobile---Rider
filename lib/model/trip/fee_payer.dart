import 'package:sanga_ride_core/sanga_ride_core.dart';

enum FeePayer {
  personal('your wallet'),
  group('your group wallet'),
  unknown(null);

  const FeePayer(this._wallet);

  final String? _wallet;

  factory FeePayer.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final isGroup = [
      reader,
      reader.objectOrNull('payment'),
      reader.objectOrNull('paymentMethod'),
    ].any((source) => source?.objectOrNull('group') != null);
    return isGroup ? group : personal;
  }

  static FeePayer of({required bool isGroup}) => isGroup ? group : personal;

  String get takenFromLabel => _wallet == null ? 'Fee charged' : 'Taken from $_wallet';

  String? get sourceValue => _wallet == null ? null : '${_wallet[0].toUpperCase()}${_wallet.substring(1)}';

  String feeFrom(String amount) => _wallet == null ? '$amount charged' : '$amount from $_wallet';

  String feeTakenNote(String amount) => _wallet == null ? '$amount was charged.' : '$amount was taken from $_wallet.';
}
