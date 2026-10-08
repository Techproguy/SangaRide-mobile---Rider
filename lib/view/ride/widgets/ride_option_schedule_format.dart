import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatRideSchedule(BuildContext context, DateTime time) {
  final clock = DateFormat(MediaQuery.alwaysUse24HourFormatOf(context) ? 'HH:mm' : 'h:mm a').format(time);
  final now = DateTime.now();
  final days = DateTime(time.year, time.month, time.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  final day = switch (days) {
    0 => 'Today',
    1 => 'Tomorrow',
    _ => DateFormat('EEE d MMM').format(time),
  };
  return '$day, $clock';
}
