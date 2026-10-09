import 'package:flutter/widgets.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class AppSplash {
  static const SangaSplashScene scene = SangaSplashScene(
    background: AssetImage(AppAssets.splashRoad),
    car: AssetImage(AppAssets.splashCar),
    carEntry: Rect.fromLTWH(-445, 637, 435, 290),
    carRest: Rect.fromLTWH(3, 535, 323, 215),
    label: 'RIDER',
  );
}
