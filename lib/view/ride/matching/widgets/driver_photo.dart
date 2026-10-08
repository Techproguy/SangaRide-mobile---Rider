import 'package:flutter/widgets.dart';
import 'package:sanga_ride/model/models.dart';

extension OfferDriverPhoto on OfferDriver {
  ImageProvider? get photo => photoUrl == null ? null : NetworkImage(photoUrl!);
}
