import 'package:intl/intl.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:share_plus/share_plus.dart';

abstract final class ReceiptShare {
  static Future<void> share(HistoryDetail detail) {
    return SharePlus.instance.share(ShareParams(text: textOf(detail), subject: 'My Sanga receipt'));
  }

  static String textOf(HistoryDetail detail) {
    final isDelivery = detail.kind.isDelivery;
    final route = detail.route;
    final driver = detail.driver?.profile;
    final vehicle = detail.vehicle;
    final delivery = detail.delivery;
    final lines = [
      isDelivery ? 'Sanga delivery receipt' : 'Sanga ride receipt',
      'Reference: ${detail.reference}',
      DateFormat('d MMM yyyy, h:mm a').format(detail.occurredAt),
      '',
      'From: ${_describe(route.pickup.name, route.pickup.address)}',
      for (final (index, stop) in route.stops.indexed) 'Stop ${index + 1}: ${_describe(stop.name, stop.address)}',
      'To: ${_describe(route.dropoff.name, route.dropoff.address)}',
      if (detail.distanceLabel != null) 'Distance: ${detail.distanceLabel}',
      if (detail.durationLabel != null) 'Time: ${detail.durationLabel}',
      if (driver != null) ..._driverLines(driver, vehicle),
      if (delivery != null) ...['', 'Package: ${delivery.itemName}', 'Recipient: ${delivery.recipientName}'],
      '',
      for (final line in detail.lines) '${line.label}: ${SangaMoney.naira(line.amount)}',
      'Total paid: ${SangaMoney.naira(detail.fare)}',
      if (detail.paidWith != null) 'Paid with: ${detail.paidWith!.label}',
      '',
      'Thanks for riding with Sanga.',
    ];
    return lines.join('\n');
  }

  static List<String> _driverLines(OfferDriver driver, DriverVehicle? vehicle) {
    return [
      '',
      'Driver: ${driver.name}',
      if (vehicle != null) 'Vehicle: ${vehicle.title}, ${vehicle.colourLabel}, ${vehicle.plateLabel}',
    ];
  }

  static String _describe(String name, String address) =>
      name == address || address.startsWith(name) ? address : '$name, $address';
}
