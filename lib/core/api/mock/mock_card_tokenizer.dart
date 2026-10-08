import 'package:sanga_ride/core/services/card_tokenizer.dart';
import 'package:sanga_ride/model/trip/wrapup/card_details.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MockCardRef {
  const MockCardRef({required this.brand, required this.last4, required this.expiry});

  final String brand;
  final String last4;
  final String expiry;
}

class MockCardTokenizer implements CardTokenizer {
  static const Duration _latency = Duration(milliseconds: 350);
  static final RegExp _mastercard = RegExp(r'^(5[1-5]|2[2-7])');

  static String brandOf(String digits) {
    if (digits.startsWith('4')) return 'visa';
    if (_mastercard.hasMatch(digits)) return 'mastercard';
    if (digits.startsWith('506') || digits.startsWith('650')) return 'verve';
    return 'other';
  }

  static MockCardRef? decode(String? token) {
    final parts = token?.split('_');
    if (parts == null || parts.length != 4 || parts.first != 'tok') return null;
    final expiry = parts[3];
    if (expiry.length != 4) return null;
    return MockCardRef(brand: parts[1], last4: parts[2], expiry: '${expiry.substring(0, 2)}/${expiry.substring(2)}');
  }

  @override
  Future<String> tokenize(CardDetails details) async {
    await Future<void>.delayed(_latency);
    final digits = SangaCardNumberFormatter.digitsOf(details.number);
    return 'tok_${brandOf(digits)}_${details.last4}_${details.expiry.replaceAll('/', '')}';
  }
}
