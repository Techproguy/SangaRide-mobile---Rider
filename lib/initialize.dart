import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:sanga_ride/controller/rider/account/account_bindings.dart';
import 'package:sanga_ride/controller/rider/airport_controller.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/controller/rider/flight_tracking_controller.dart';
import 'package:sanga_ride/controller/rider/groups/group_bindings.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/controller/rider/ride_history_controller.dart';
import 'package:sanga_ride/controller/rider/saved_places_controller.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/controller/rider/safety/safety_bindings.dart';
import 'package:sanga_ride/controller/rider/trip/trip_bindings.dart';
import 'package:sanga_ride/controller/rider/trip/trip_wrapup_bindings.dart';
import 'package:sanga_ride/controller/rider/wallet_bindings.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/controller/shared/map_controller.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/mock/mock_card_tokenizer.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/services/card_tokenizer.dart';
import 'package:sanga_ride/core/services/connectivity_service.dart';
import 'package:sanga_ride/core/services/secure_token_store.dart';
import 'package:sanga_ride/view/widgets/map/sanga_marker_icons.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> initializeSanga() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await SecureTokenStore.instance.hydrate();
  unawaited(SangaMarkerIcons.preload());
  await SangaFrame.preload(SangaConstants.frame);
  await SangaPhotoBackdrop.precache([for (final image in AppAssets.firstScreenPhotos) AssetImage(image)]);

  Get.put(ApiService(), permanent: true);
  Get.put(ConnectivityService(), permanent: true);
  Get.put<CardTokenizer>(MockCardTokenizer(), permanent: true);

  Get.put(AuthController(), permanent: true);
  Get.lazyPut(() => RiderSignUpController(), fenix: true);
  Get.lazyPut(() => RideRequestController(), fenix: true);
  Get.lazyPut(() => RideMatchController(), fenix: true);
  Get.lazyPut(() => RideForController(), fenix: true);
  Get.lazyPut(() => ScheduledRidesController(), fenix: true);
  Get.lazyPut(() => SavedPlacesController(), fenix: true);
  Get.lazyPut(() => RideHistoryController(), fenix: true);
  Get.lazyPut(() => AirportController(), fenix: true);
  Get.lazyPut(() => SendDeliveryController(), fenix: true);
  Get.lazyPut(() => FlightTrackingController(), fenix: true);
  Get.lazyPut(() => RiderHomeController(), fenix: true);
  Get.put(UserController(), permanent: true);

  Get.lazyPut(() => MapController(), fenix: true);
  registerTripControllers();
  registerTripWrapUpControllers();
  registerWalletControllers();
  registerGroupControllers();
  registerSafetyControllers();
  registerAccountControllers();
}
