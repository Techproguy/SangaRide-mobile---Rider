import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/add_stop_controller.dart';
import 'package:sanga_ride/controller/rider/trip/cancel_controller.dart';
import 'package:sanga_ride/controller/rider/trip/delivery_issue_controller.dart';
import 'package:sanga_ride/controller/rider/trip/delivery_pickup_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';

void registerTripControllers() {
  Get.lazyPut(() => TripController(), fenix: true);
  Get.lazyPut(() => AddStopController(), fenix: true);
  Get.lazyPut(() => CancelController(), fenix: true);
  Get.lazyPut(() => DeliveryIssueController(), fenix: true);
  Get.lazyPut(() => DeliveryPickupController(), fenix: true);
}
