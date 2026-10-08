import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class WalletFormat {
  static final DateFormat _clock = DateFormat('h:mm a');
  static final DateFormat _day = DateFormat('EEE, d MMM');
  static final DateFormat _shortDay = DateFormat('d MMM');
  static final DateFormat _stamp = DateFormat('d MMM y · h:mm a');

  static String money(int amount) => SangaMoney.naira(amount);

  static String signed(int amount) => '${amount < 0 ? '-' : '+'}${SangaMoney.naira(amount.abs())}';

  static String clock(DateTime time) => _lower(_clock.format(time));

  static String stamp(DateTime time) => _lower(_stamp.format(time));

  static String dayHeading(DateTime day, {DateTime? now}) {
    final offset = DateUtils.dateOnly(now ?? DateTime.now()).difference(DateUtils.dateOnly(day)).inDays;
    return switch (offset) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => _day.format(day),
    };
  }

  static String recent(DateTime time, {DateTime? now}) {
    final heading = dayHeading(time, now: now);
    final isNear = heading == 'Today' || heading == 'Yesterday';
    return '${isNear ? heading : _shortDay.format(time)}, ${clock(time)}';
  }

  static String _lower(String text) => text.replaceAll(' ', ' ').replaceAll('AM', 'am').replaceAll('PM', 'pm');
}
