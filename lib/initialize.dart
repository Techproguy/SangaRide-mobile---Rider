import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/controller/shared/map_controller.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/core/services/connectivity_service.dart';
import 'package:sanga_ride/core/services/secure_token_store.dart';
import 'package:sanga_ride/view/widgets/map/sanga_marker_icons.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> initializeSanga() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await SecureTokenStore.instance.hydrate();
  unawaited(SangaMarkerIcons.preload());
  await SangaPhotoBackdrop.precache([for (final image in AppAssets.firstScreenPhotos) AssetImage(image)]);

  Get.put(ApiService(), permanent: true);
  Get.put(ConnectivityService(), permanent: true);

  Get.put(AuthController(), permanent: true);
  Get.put(UserController(), permanent: true);

  Get.lazyPut(() => MapController(), fenix: true);
}
