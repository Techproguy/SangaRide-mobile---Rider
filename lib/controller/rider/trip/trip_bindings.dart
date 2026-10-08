import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';

void registerTripControllers() {
  Get.lazyPut(() => TripController(), fenix: true);
}
