import 'package:intl/intl.dart';

extension NumFormatting on num {
  String clean() {
    if (this == 0) return '0';
    return this % 1 == 0 ? toInt().toString() : toString();
  }

  String get naira => '₦${NumberFormat('#,##0').format(this)}';
}
