import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideTimingScreen extends StatefulWidget {
  const RideTimingScreen({super.key});

  @override
  State<RideTimingScreen> createState() => _RideTimingScreenState();
}

class _RideTimingScreenState extends State<RideTimingScreen> {
  static const _leadTime = Duration(minutes: 15);
  static const _bookingWindow = Duration(days: 30);

  final _ride = Get.find<RideRequestController>();
  final _scheduleText = TextEditingController();
  DateTime? _schedule;

  static IconData _iconFor(RideTiming timing) => switch (timing) {
    RideTiming.now => Icons.schedule_rounded,
    _ => Icons.event_rounded,
  };

  @override
  void initState() {
    super.initState();
    final scheduledAt = _ride.scheduledAt;
    if (_ride.timing == RideTiming.later && scheduledAt != null) _schedule = scheduledAt;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final schedule = _schedule;
    if (schedule != null) _scheduleText.text = formatRideSchedule(context, schedule);
  }

  @override
  void dispose() {
    _scheduleText.dispose();
    super.dispose();
  }

  bool get _isTooSoon => _schedule?.isBefore(DateTime.now().add(_leadTime)) ?? false;

  bool get _canConfirm => _ride.timing == RideTiming.now || (_schedule != null && !_isTooSoon);

  void _syncLater() => _ride.setTiming(RideTiming.later, scheduledAt: _isTooSoon ? null : _schedule);

  void _select(RideTiming timing) {
    if (timing == RideTiming.now) return _ride.setTiming(RideTiming.now);
    _syncLater();
  }

  Future<void> _pickSchedule() async {
    FocusScope.of(context).unfocus();
    final earliest = DateTime.now().add(_leadTime);
    final picked = await showSangaDateTimeSheet(
      context: context,
      title: 'Pick up date and time',
      minimumDate: earliest,
      maximumDate: earliest.add(_bookingWindow),
      initialDateTime: _isTooSoon ? null : _schedule,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _schedule = picked;
      _scheduleText.text = formatRideSchedule(context, picked);
    });
    _syncLater();
  }

  void _confirm() {
    if (_ride.timing == RideTiming.later && _isTooSoon) {
      setState(_syncLater);
      return;
    }
    context.push(SangaRoutes.rideReview);
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
              for (final timing in RideTiming.values)
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
                child: _ride.timing == RideTiming.later ? _buildSchedule() : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedule() {
    return SangaTextField(
      label: 'Pick up date and time',
      hintText: 'Choose when',
      controller: _scheduleText,
      onTap: _pickSchedule,
      errorText: _isTooSoon ? 'That time has passed. Pick a new one.' : null,
      trailing: const Icon(Icons.event_rounded, color: SangaColors.textMuted),
    );
  }
}
