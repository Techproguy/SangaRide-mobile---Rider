import 'package:flutter/widgets.dart';
import 'package:sanga_ride/model/models.dart';

final Map<String, ImageProvider> _photoProviders = {};

extension OfferDriverPhoto on OfferDriver {
  ImageProvider? get photo {
    final url = photoUrl;
    if (url == null) return null;
    return _photoProviders.putIfAbsent(url.split('?').first, () => NetworkImage(url));
  }
}
