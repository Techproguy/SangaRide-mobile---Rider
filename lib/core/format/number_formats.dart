import 'package:intl/intl.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class NumberFormats {
  static NumberFormat get groupedMoney => SangaMoney.grouped();
  static final NumberFormat grouped = NumberFormat('#,##0');

  static Money? moneyOf(int? wholeUnits) => wholeUnits == null ? null : Money.major(wholeUnits);

  static String plain(Money money) => money.minor % Money.minorPerMajor == 0
      ? '${money.wholeMajor}'
      : (money.minor / Money.minorPerMajor).toStringAsFixed(2);

  static String groupedWhole(Money money) => groupedMoney.format(money.wholeMajor);
}
