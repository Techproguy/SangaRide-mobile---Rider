import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? secure, GetStorage? box})
    : _secure = secure ?? _defaultSecure,
      _box = box ?? GetStorage();

  static SecureTokenStore instance = SecureTokenStore();

  static const _defaultSecure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device, synchronizable: false),
  );

  static const kAccess = 'access_token';
  static const kRefresh = 'refresh_token';
  static const kInstallMarker = 'secure_token_install_marker';

  final FlutterSecureStorage _secure;
  final GetStorage _box;

  final ValueNotifier<int> sessionRevision = ValueNotifier<int>(0);

  String? _access;
  String? _refresh;
  bool _hydrated = false;
  Future<void> _writes = Future<void>.value();

  bool get isHydrated => _hydrated;

  String? get accessToken => _cached(_access);

  String? get refreshToken => _cached(_refresh);

  bool get hasSession => (accessToken ?? '').isNotEmpty;

  String? _cached(String? value) {
    assert(_hydrated, 'SecureTokenStore read before hydrate(). Hydrate it in initializeSanga().');
    return _hydrated ? value : null;
  }

  Future<void> hydrate() async {
    if (_hydrated) return;
    try {
      _access = await _secure.read(key: kAccess);
      _refresh = await _secure.read(key: kRefresh);
    } catch (e) {
      log('SecureTokenStore: keystore unreadable, no session this launch: $e');
      _access = null;
      _refresh = null;
    }

    final isFreshInstall = _box.read(kInstallMarker) == null;
    if (isFreshInstall && _access != null) {
      await _delete(kAccess);
      await _delete(kRefresh);
      _access = null;
      _refresh = null;
    }
    await _box.write(kInstallMarker, '1');
    _hydrated = true;
  }

  Future<void> saveSession({required String accessToken, String? refreshToken}) {
    _access = accessToken;
    _refresh = refreshToken ?? _refresh;
    return _writes = _writes.then((_) async {
      await _write(kAccess, accessToken);
      if (refreshToken != null) await _write(kRefresh, refreshToken);
      sessionRevision.value++;
    });
  }

  Future<void> clear() {
    _access = null;
    _refresh = null;
    return _writes = _writes.then((_) async {
      await _delete(kAccess);
      await _delete(kRefresh);
      sessionRevision.value++;
    });
  }

  Future<void> _write(String key, String value) async {
    try {
      await _secure.write(key: key, value: value);
    } catch (e) {
      log('SecureTokenStore: write($key) failed: $e');
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _secure.delete(key: key);
    } catch (e) {
      log('SecureTokenStore: delete($key) failed: $e');
    }
  }
}
