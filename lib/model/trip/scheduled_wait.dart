import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ScheduledWait {
  const ScheduledWait({
    required this.pickupAt,
    required this.arriveByAt,
    required this.freeWaitUntil,
    required this.feePerMinute,
  });

  static ScheduledWait? maybeFrom(JsonReader json, {required DateTime? pickupAt}) {
    final arriveByAt = json.timeOrNull('arriveByAt');
    final freeWaitUntil = json.timeOrNull('freeWaitUntil');
    final feePerMinute = json.moneyOrNull('waitingFeePerMinute');
    if (pickupAt == null || arriveByAt == null || freeWaitUntil == null || feePerMinute == null) return null;
    return ScheduledWait(
      pickupAt: pickupAt.toLocal(),
      arriveByAt: arriveByAt.toLocal(),
      freeWaitUntil: freeWaitUntil.toLocal(),
      feePerMinute: feePerMinute,
    );
  }

  final DateTime pickupAt;
  final DateTime arriveByAt;
  final DateTime freeWaitUntil;
  final Money feePerMinute;

  int get arriveEarlyMinutes => pickupAt.difference(arriveByAt).inMinutes;

  int get freeAfterMinutes => freeWaitUntil.difference(pickupAt).inMinutes;
}
