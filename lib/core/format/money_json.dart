import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

extension MoneyJson on JsonReader {
  Money money(String key) => Money.parse(raw[key]);

  Money? moneyOrNull(String key) => Money.tryParse(raw[key]);

  Money moneyOr(String key, Money fallback) => Money.tryParse(raw[key]) ?? fallback;
}
