import 'package:intl/intl.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class NumberFormats {
  static NumberFormat get groupedMoney => SangaMoney.grouped();
  static final NumberFormat grouped = NumberFormat('#,##0');
}
