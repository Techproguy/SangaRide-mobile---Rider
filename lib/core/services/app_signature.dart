import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sanga_ride/core/constants.dart';

class AppSignature {
  AppSignature._();

  static const _channel = MethodChannel('${SangaConstants.androidPackageName}/app_signature');
  static String? _cached;

  static Future<String?> androidCertSha1() async {
    if (!Platform.isAndroid) return null;
    if (_cached != null) return _cached;
    try {
      _cached = await _channel.invokeMethod<String>('getCertSha1');
    } catch (_) {
      _cached = null;
    }
    return _cached;
  }
}
