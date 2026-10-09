import 'package:intl/intl.dart';

abstract final class ClockFormats {
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _weekdayDate = DateFormat('EEE d MMM yyyy');
  static final DateFormat _dayMonth = DateFormat('d MMM');

  static String time(DateTime value) => _time.format(value);

  static String weekdayDate(DateTime value) => _weekdayDate.format(value);

  static String dayMonth(DateTime value) => _dayMonth.format(value);
}
