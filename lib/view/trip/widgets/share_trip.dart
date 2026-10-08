import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareTrip(String tripId, {bool isDelivery = false}) {
  final noun = isDelivery ? 'delivery' : 'ride';
  return SharePlus.instance.share(
    ShareParams(text: 'Follow my Sanga $noun live: ${TripController.shareLinkOf(tripId)}', subject: 'My Sanga $noun'),
  );
}
