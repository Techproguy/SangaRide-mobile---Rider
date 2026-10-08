import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract final class TimeFormat {
  static final _clock = DateFormat('h:mm a');
  static final _day = DateFormat('d MMM');
  static final _dayYear = DateFormat('d MMM y');
  static final _long = DateFormat('MMMM d, y');

  static String clock(DateTime time) => _clock.format(time).toLowerCase();

  static String date(DateTime time) => DateUtils.isSameDay(time, DateTime.now().toLocal()) ? 'Today' : _dayShort(time);

  static String longDate(DateTime time) => _long.format(time);

  static String ago(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final difference = current.difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24 && DateUtils.isSameDay(time, current)) return '${difference.inHours} hr ago';
    final yesterday = DateUtils.dateOnly(current).subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(time, yesterday)) return 'Yesterday, ${clock(time)}';
    return '${_dayShort(time)}, ${clock(time)}';
  }

  static String daySeparator(DateTime time) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(time, now)) return 'Today';
    if (DateUtils.isSameDay(time, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return _dayShort(time);
  }

  static String _dayShort(DateTime time) =>
      time.year == DateTime.now().year ? _day.format(time) : _dayYear.format(time);
}
