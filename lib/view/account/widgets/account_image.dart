import 'package:flutter/painting.dart';

ImageProvider? accountImageOf(String? url) {
  if (url == null || url.isEmpty) return null;
  return url.startsWith('assets/') ? AssetImage(url) : NetworkImage(url);
}
