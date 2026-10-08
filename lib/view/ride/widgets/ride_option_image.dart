import 'package:flutter/widgets.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/model/models.dart';

extension RideOptionImage on RideCategory {
  ImageProvider get image => AssetImage(switch (this) {
    RideCategory.go => AppAssets.rideGo,
    RideCategory.plus => AppAssets.ridePlus,
    RideCategory.xl => AppAssets.rideXl,
    RideCategory.lux => AppAssets.rideLux,
    RideCategory.moto => AppAssets.rideMoto,
    RideCategory.assist => AppAssets.rideAssist,
  });
}
