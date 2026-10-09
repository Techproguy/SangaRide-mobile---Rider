import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareTrip(String tripId, {bool isDelivery = false}) async {
  final link = await Get.find<TripController>().createShareLink();
  if (link == null) return;
  final noun = isDelivery ? 'delivery' : 'ride';
  await SharePlus.instance.share(ShareParams(text: 'Follow my Sanga $noun live: $link', subject: 'My Sanga $noun'));
}
