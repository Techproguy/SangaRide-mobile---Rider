import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/view/ride/widgets/booking_picker_field.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideTimingScreen extends StatefulWidget {
  const RideTimingScreen({super.key});

  @override
  State<RideTimingScreen> createState() => _RideTimingScreenState();
}

class _RideTimingScreenState extends State<RideTimingScreen> {
  final _ride = Get.find<RideRequestController>();
  DateTime? _schedule;

  static IconData _iconFor(RideTiming timing) => switch (timing) {
    RideTiming.now => Icons.schedule_rounded,
    RideTiming.later => Icons.event_rounded,
    RideTiming.repeat => Icons.repeat_rounded,
  };

  @override
  void initState() {
    super.initState();
    final scheduledAt = _ride.scheduledAt;
    if (_ride.timing == RideTiming.later && scheduledAt != null) _schedule = scheduledAt;
  }

  List<RideTiming> get _timings => [
    for (final timing in RideTiming.values)
      if (timing != RideTiming.repeat || _ride.tripType.allowsRepeat) timing,
  ];

  DateTime get _earliest => DateTime.now().add(BookingRules.scheduleLeadTime);

  bool get _isTooSoon => _schedule?.isBefore(_earliest) ?? false;

  bool get _canConfirm => switch (_ride.timing) {
    RideTiming.now => true,
    RideTiming.later => _schedule != null && !_isTooSoon,
    RideTiming.repeat => _ride.repeatRule != null,
  };

  void _syncLater() => _ride.setTiming(RideTiming.later, scheduledAt: _isTooSoon ? null : _schedule);

  void _select(RideTiming timing) {
    switch (timing) {
      case RideTiming.now || RideTiming.repeat:
        _ride.setTiming(timing);
      case RideTiming.later:
        _syncLater();
    }
  }

  Future<void> _pickSchedule() async {
    final earliest = _earliest;
    final picked = await showSangaDateTimeSheet(
      context: context,
      title: 'Pick up date and time',
      minimumDate: earliest,
      maximumDate: earliest.add(BookingRules.bookingWindow),
      initialDateTime: _isTooSoon ? null : _schedule,
    );
    if (picked == null || !mounted) return;
    setState(() => _schedule = picked);
    _syncLater();
  }

  void _confirm() {
    if (_ride.timing == RideTiming.later && _isTooSoon) {
      setState(_syncLater);
      return;
    }
    context.push(BookingRoutes.afterTiming(_ride.tripType));
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'When do you want to ride?',
      footer: Obx(() => SangaButton.primary(label: 'Confirm', onPressed: _canConfirm ? _confirm : null)),
      children: [
        Obx(
          () => Column(
            spacing: SangaSpacing.md,
            children: [
              for (final timing in _timings)
                SangaOptionCard(
                  leading: SangaIconBadge(child: Icon(_iconFor(timing))),
                  title: timing.label,
                  subtitle: timing.description,
                  isSelected: _ride.timing == timing,
                  onTap: () => _select(timing),
                ),
              AnimatedSize(
                duration: SangaMotion.morph,
                curve: SangaMotion.springBlock,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.hardEdge,
                child: switch (_ride.timing) {
                  RideTiming.now => const SizedBox(width: double.infinity),
                  RideTiming.later => _buildSchedule(),
                  RideTiming.repeat => _buildRepeat(),
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedule() {
    final schedule = _schedule;
    return BookingPickerField(
      label: 'Pick up date and time',
      hintText: 'Choose when',
      icon: Icons.event_rounded,
      value: schedule == null ? null : formatRideSchedule(context, schedule),
      onTap: _pickSchedule,
      errorText: _isTooSoon ? 'That time has passed. Pick a new one.' : null,
    );
  }

  Widget _buildRepeat() {
    final rule = _ride.repeatRule;
    return BookingPickerField(
      label: 'Repeat schedule',
      hintText: 'Choose days and time',
      icon: Icons.repeat_rounded,
      value: rule == null ? null : formatRepeatRule(context, rule),
      onTap: () => context.push(BookingRoutes.repeatSetup),
    );
  }
}
