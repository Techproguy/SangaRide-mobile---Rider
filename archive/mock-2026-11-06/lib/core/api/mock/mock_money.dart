import 'package:sanga_ride/core/api/mock/mock_account.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class MockMoney {
  static const int _nairaPerDollar = 1000;
  static const double _kilometersPerMile = 1.609344;

  static SangaRegion get region => SangaRegion.ofPhone(MockAccount.phone) ?? SangaRegion.ng;

  static bool get isUnitedStates => region == SangaRegion.us;

  static String get currency => region.currencyCode;

  static Money of(num naira) => isUnitedStates
      ? Money((naira * Money.minorPerMajor / _nairaPerDollar).round(), SangaRegion.us.currencyCode)
      : Money.major(naira, SangaRegion.ng.currencyCode);

  static Map<String, Object> json(num naira) => of(naira).toJson();

  static Map<String, Object>? jsonOrNull(num? naira) => naira == null ? null : json(naira);

  static Map<String, Object> perDistanceJson(num nairaPerKilometer) =>
      json(isUnitedStates ? nairaPerKilometer * _kilometersPerMile : nairaPerKilometer);

  static String label(num naira) => of(naira).format();

  static num nairaPerKilometer(Object? raw) {
    final perDistance = naira(raw);
    return isUnitedStates ? perDistance / _kilometersPerMile : perDistance;
  }

  static num? nairaOrNull(Object? raw) => raw == null ? null : naira(raw);

  static num naira(Object? raw) {
    final money = Money.tryParse(raw, currency: currency);
    if (money == null) return 0;
    if (money.currency == SangaRegion.us.currencyCode) return money.minor * _nairaPerDollar / Money.minorPerMajor;
    return money.major;
  }
}
