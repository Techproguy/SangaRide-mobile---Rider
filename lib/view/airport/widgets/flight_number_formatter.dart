import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:sanga_ride/model/models.dart';

class FlightNumberFormatter extends TextInputFormatter {
  const FlightNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = FlightNumber.clean(newValue.text);
    final text = cleaned.length > AirportRules.flightFieldLength
        ? cleaned.substring(0, AirportRules.flightFieldLength)
        : cleaned;
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: math.min(newValue.selection.end, text.length)),
    );
  }
}
