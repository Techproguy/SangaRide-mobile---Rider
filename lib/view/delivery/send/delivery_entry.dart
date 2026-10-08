import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/delivery_routes.dart';
import 'package:sanga_ride/model/models.dart';

Future<void> openDelivery(BuildContext context, {Place? pickup}) async {
  Get.find<RideForController>().reset();
  Get.find<RideRequestController>()
    ..start(pickup: pickup)
    ..setTripType(TripType.delivery);
  Get.find<SendDeliveryController>().begin();
  await context.push(DeliveryRoutes.kind);
}
