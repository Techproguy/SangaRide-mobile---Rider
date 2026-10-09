import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/view/ride/widgets/booking_note.dart';
import 'package:sanga_ride/view/ride/widgets/booking_picker_field.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RepeatSetupScreen extends StatefulWidget {
  const RepeatSetupScreen({super.key});

  @override
  State<RepeatSetupScreen> createState() => _RepeatSetupScreenState();
}

class _RepeatSetupScreenState extends State<RepeatSetupScreen> {
  static const Duration _endDateSpan = Duration(days: 365);

  final _ride = Get.find<RideRequestController>();
  late Set<Weekday> _days;
  DateTime? _time;
  late DateTime _start;
  DateTime? _end;

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    super.initState();
    final rule = _ride.repeatRule;
    _days = {...?rule?.weekdays};
    _time = rule?.timeOfDay;
    _start = rule == null ? _dateOnly(BookingClock.now()) : _dateOnly(rule.startDate);
    _end = rule?.endDate;
  }

  RepeatRule? get _rule {
    final time = _time;
    if (_days.isEmpty || time == null) return null;
    return RepeatRule(weekdays: _days, hour: time.hour, minute: time.minute, startDate: _start, endDate: _end);
  }

  void _toggleDay(Weekday day, bool isSelected) {
    setState(() => isSelected ? _days.add(day) : _days.remove(day));
  }

  Future<void> _pickTime() async {
    final today = _dateOnly(BookingClock.now());
    final time = _time;
    final picked = await showSangaDateTimeSheet(
      context: context,
      title: 'Time of day',
      minimumDate: today,
      maximumDate: today.add(const Duration(hours: 23, minutes: 55)),
      initialDateTime: time == null
          ? today.add(const Duration(hours: 8))
          : today.add(Duration(hours: time.hour, minutes: time.minute)),
    );
    if (picked != null) setState(() => _time = DateTime(2000, 1, 1, picked.hour, picked.minute));
  }

  Future<void> _pickStart() async {
    final today = _dateOnly(BookingClock.now());
    final picked = await showSangaDateSheet(
      context: context,
      title: 'Start date',
      initialDate: _start.isBefore(today) ? today : _start,
      firstDate: today,
      lastDate: today.add(_ride.rules.bookingWindow),
    );
    if (picked == null) return;
    setState(() {
      _start = _dateOnly(picked);
      if (_end?.isBefore(_start) ?? false) _end = null;
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showSangaDateSheet(
      context: context,
      title: 'End date',
      initialDate: _end ?? _start,
      firstDate: _start,
      lastDate: _start.add(_endDateSpan),
    );
    if (picked != null) setState(() => _end = _dateOnly(picked));
  }

  void _confirm(RepeatRule rule) {
    _ride.setRepeatRule(rule);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final rule = _rule;
    final time = _time;
    final firstRide = rule?.firstRideAfter(BookingClock.now());
    return SangaPageLayout(
      title: 'When do you want to ride?',
      footer: SangaButton.primary(label: 'Confirm', onPressed: rule == null ? null : () => _confirm(rule)),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            BookingPickerField(
              label: 'Time',
              hintText: 'Choose daily time',
              icon: Icons.schedule_rounded,
              value: time == null ? null : formatRideClock(context, time),
              onTap: _pickTime,
            ),
            _weekdays(),
            BookingPickerField(
              label: 'Start date',
              hintText: 'Choose date',
              icon: Icons.event_rounded,
              value: formatRideDate(_start),
              onTap: _pickStart,
            ),
            BookingPickerField(
              label: 'End date (optional)',
              hintText: 'Keeps going until you cancel',
              icon: Icons.event_rounded,
              value: _end == null ? null : formatRideDate(_end!),
              onTap: _pickEnd,
              trailing: _end == null
                  ? null
                  : GestureDetector(
                      onTap: () => setState(() => _end = null),
                      child: const Icon(Icons.close_rounded, color: SangaColors.textMuted),
                    ),
            ),
            if (rule != null) _summary(rule, firstRide),
          ],
        ),
      ],
    );
  }

  Widget _weekdays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.sm,
      children: [
        const Text('When to repeat', style: SangaTextStyles.label),
        Wrap(
          spacing: SangaSpacing.xs,
          runSpacing: SangaSpacing.xs,
          children: [
            for (final day in Weekday.values)
              SangaChoiceChip(
                label: day.label,
                isSelected: _days.contains(day),
                onSelected: (isSelected) => _toggleDay(day, isSelected),
              ),
          ],
        ),
      ],
    );
  }

  Widget _summary(RepeatRule rule, DateTime? firstRide) {
    final summary = formatRepeatRule(context, rule);
    final message = firstRide == null
        ? '$summary. No rides fall between those dates.'
        : '$summary. Your first ride is ${formatRideSchedule(context, firstRide)}.';
    return BookingNote(message: message);
  }
}
