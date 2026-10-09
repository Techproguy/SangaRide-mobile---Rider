import 'package:flutter/services.dart';

abstract final class InviteCode {
  static const int length = 8;
  static const int groupSize = 4;

  static final RegExp _unsafe = RegExp(r'[^A-Za-z0-9]');

  static String clean(String input) {
    final cleaned = input.toUpperCase().replaceAll(_unsafe, '');
    return cleaned.length > length ? cleaned.substring(0, length) : cleaned;
  }

  static String group(String code) {
    final cleaned = clean(code);
    if (cleaned.length <= groupSize) return cleaned;
    return '${cleaned.substring(0, groupSize)}-${cleaned.substring(groupSize)}';
  }

  static bool isComplete(String input) => clean(input).length == length;
}

class InviteCodeFormatter extends TextInputFormatter {
  const InviteCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var cleaned = InviteCode.clean(newValue.text);
    final caret = newValue.selection.end.clamp(0, newValue.text.length);
    var charsBeforeCaret = InviteCode.clean(newValue.text.substring(0, caret)).length;
    final removedOnlyDash = newValue.text.length < oldValue.text.length && cleaned == InviteCode.clean(oldValue.text);
    if (removedOnlyDash && charsBeforeCaret > 0) {
      cleaned = cleaned.substring(0, charsBeforeCaret - 1) + cleaned.substring(charsBeforeCaret);
      charsBeforeCaret -= 1;
    }
    final text = InviteCode.group(cleaned);
    final offset = charsBeforeCaret > InviteCode.groupSize ? charsBeforeCaret + 1 : charsBeforeCaret;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset.clamp(0, text.length)),
    );
  }
}
