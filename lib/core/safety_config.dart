import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class SafetyConfig {
  static String get emergencyNumber => SangaRegion.current.emergencyNumber;
  static const Duration sosGrace = Duration(seconds: 5);

  static String numberOr(String? fromServer) {
    final trimmed = fromServer?.trim() ?? '';
    return trimmed.isEmpty ? emergencyNumber : trimmed;
  }
}
