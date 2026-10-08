import 'dart:io';

class SangaStorageKeys {
  SangaStorageKeys._();

  static const String user = 'user';
  static const String lastCity = 'last_city';
}

class SangaMapsKeys {
  SangaMapsKeys._();

  static const String _android = String.fromEnvironment('MAPS_API_KEY_ANDROID');
  static const String _ios = String.fromEnvironment('MAPS_API_KEY_IOS');

  static bool get isConfigured => (Platform.isIOS ? _ios : _android).isNotEmpty;

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
