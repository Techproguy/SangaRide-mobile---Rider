import 'package:intl/intl.dart';

abstract final class NumberFormats {
  static final NumberFormat groupedNigeria = NumberFormat('#,##0', 'en_NG');
  static final NumberFormat grouped = NumberFormat('#,##0');
}
