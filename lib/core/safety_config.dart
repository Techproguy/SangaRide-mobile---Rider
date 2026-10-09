abstract final class SafetyConfig {
  static const String emergencyNumber = '112';
  static const Duration sosGrace = Duration(seconds: 5);

  static String numberOr(String? fromServer) {
    final trimmed = fromServer?.trim() ?? '';
    return trimmed.isEmpty ? emergencyNumber : trimmed;
  }
}
