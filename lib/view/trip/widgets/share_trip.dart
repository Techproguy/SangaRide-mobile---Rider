import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareTrip(String tripId) {
  return SharePlus.instance.share(
    ShareParams(text: 'Follow my Sanga ride live: ${TripController.shareLinkOf(tripId)}', subject: 'My Sanga ride'),
  );
}
