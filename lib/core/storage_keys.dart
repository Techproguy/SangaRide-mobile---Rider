import 'dart:io';

class SangaStorageKeys {
  SangaStorageKeys._();

  static const String user = 'user';
  static const String lastCity = 'last_city';
  static const String permissionPrimedPrefix = 'permission_primed_';
  static const String permissionOfferedPrefix = 'permission_offered_';
}

class SangaMapsKeys {
  SangaMapsKeys._();

  static const String _android = String.fromEnvironment('MAPS_API_KEY_ANDROID');
  static const String _ios = String.fromEnvironment('MAPS_API_KEY_IOS');

  static const String _placeholderPrefix = 'replace-with';

  static bool get isConfigured {
    final key = Platform.isIOS ? _ios : _android;
    return key.isNotEmpty && !key.startsWith(_placeholderPrefix);
  }

  static String get defaultKey {
    final key = Platform.isIOS ? _ios : _android;
    assert(
      key.isNotEmpty,
      'Maps key missing. Copy dart_defines/ride.example.json to dart_defines/ride.json, '
      'fill it in, and run with --dart-define-from-file=dart_defines/ride.json',
    );
    return key;
  }
}
