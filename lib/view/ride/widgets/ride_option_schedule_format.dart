import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/model/ride/booking.dart';

String formatRideClock(BuildContext context, DateTime time) =>
    DateFormat(MediaQuery.alwaysUse24HourFormatOf(context) ? 'HH:mm' : 'h:mm a').format(time);

String formatRideSchedule(BuildContext context, DateTime time) {
  final clock = formatRideClock(context, time);
  final now = DateTime.now();
  final days = DateTime(time.year, time.month, time.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  final day = switch (days) {
    0 => 'Today',
    1 => 'Tomorrow',
    _ => DateFormat('EEE d MMM').format(time),
  };
  return '$day, $clock';
}

String formatRideMoment(BuildContext context, DateTime time) {
  final clock = formatRideClock(context, time);
  final now = DateTime.now();
  final days = DateTime(time.year, time.month, time.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  final day = switch (days) {
    0 => 'today',
    1 => 'tomorrow',
    _ => 'on ${DateFormat('EEE d MMM').format(time)}',
  };
  return '$day at $clock';
}

String formatRideDate(DateTime date) => DateFormat('EEE d MMM yyyy').format(date);

String formatRepeatRule(BuildContext context, RepeatRule rule) =>
    '${rule.daysLabel} at ${formatRideClock(context, rule.timeOfDay)}';

String formatRideDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return switch ((hours, minutes)) {
    (0, final minutes) => '$minutes min',
    (final hours, 0) => hours == 1 ? '1 hour' : '$hours hours',
    (final hours, final minutes) => '${hours}h ${minutes}m',
  };
}
