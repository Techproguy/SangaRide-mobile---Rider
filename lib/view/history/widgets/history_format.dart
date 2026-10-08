import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';

String formatHistoryWhen(BuildContext context, DateTime time) {
  final clock = formatRideClock(context, time);
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(time.year, time.month, time.day)).inDays;
  final day = switch (days) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => DateFormat(time.year == now.year ? 'EEE d MMM' : 'd MMM yyyy').format(time),
  };
  return '$day, $clock';
}

String formatHistoryDate(DateTime time) => DateFormat('d MMM yyyy').format(time);
