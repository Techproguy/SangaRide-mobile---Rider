import 'package:flutter/widgets.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';

extension TripWaitCopy on Trip {
  String? enRouteWaitNotice(BuildContext context) {
    final wait = scheduledWait;
    if (wait == null) return null;
    final arriveBy = formatRideClock(context, wait.arriveByAt);
    return 'Your driver will be there by $arriveBy. ${wait.freeWaitSentence(context)}';
  }

  String? arrivedWaitNotice(BuildContext context) {
    final wait = scheduledWait;
    if (wait != null) return wait.freeWaitSentence(context);
    final minutes = freeWait.inMinutes;
    if (minutes <= 0) return null;
    return 'Your driver will wait up to $minutes ${minutes == 1 ? 'minute' : 'minutes'} for you.';
  }
}

extension ScheduledWaitCopy on ScheduledWait {
  String freeWaitSentence(BuildContext context) =>
      'Waiting is free until ${formatRideClock(context, freeWaitUntil)}, then ${feePerMinute.format()} a minute.';

  String arriveByValue(BuildContext context) =>
      '${formatRideClock(context, arriveByAt)} ($arriveEarlyMinutes min early)';

  String freeWaitValue(BuildContext context) =>
      'Until ${formatRideClock(context, freeWaitUntil)}, then ${feePerMinute.format()} a minute';
}
