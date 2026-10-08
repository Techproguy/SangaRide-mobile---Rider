import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_payment_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_rating_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_receipt_controller.dart';

void registerTripWrapUpControllers() {
  Get.lazyPut(() => TripPaymentController(), fenix: true);
  Get.lazyPut(() => TripReceiptController(), fenix: true);
  Get.lazyPut(() => TripRatingController(), fenix: true);
}
