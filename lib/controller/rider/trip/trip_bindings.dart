import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/add_stop_controller.dart';
import 'package:sanga_ride/controller/rider/trip/cancel_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';

void registerTripControllers() {
  Get.lazyPut(() => TripController(), fenix: true);
  Get.lazyPut(() => AddStopController(), fenix: true);
  Get.lazyPut(() => CancelController(), fenix: true);
}
