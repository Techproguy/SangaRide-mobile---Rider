import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';

void rebookRide(BuildContext context, HistoryRoute route, RideCategory category) {
  Get.find<RideForController>().reset();
  final ride = Get.find<RideRequestController>();
  ride.start(pickup: route.pickup, dropoff: route.dropoff, category: category);
  for (final stop in route.stops) {
    ride.applyRouteEdit(const RouteEdit.stop(), stop);
  }
  context.push(SangaRoutes.rideRoute);
}
