import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/extend_trip_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/trip/widgets/trip_page_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ExtendTripScreen extends StatefulWidget {
  const ExtendTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<ExtendTripScreen> createState() => _ExtendTripScreenState();
}

class _ExtendTripScreenState extends State<ExtendTripScreen> {
  static const String _title = 'Extend your trip';

  final _extend = Get.find<ExtendTripController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _extend.open(widget.tripId));
  }

  Future<void> _confirm() async {
    final isDone = await _extend.confirm();
    if (isDone && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return TripPageGate(
      tripId: widget.tripId,
      title: _title,
      child: Obx(
        () => SangaPageLayout(
          title: _title,
          footer: SangaButton.primary(
            label: 'Confirm extension',
            isLoading: _extend.isApplying.value,
            onPressed: _extend.canConfirm ? _confirm : null,
          ),
          children: [
            RideOptionAsyncState(
              isLoading: _extend.quoting.isNotEmpty && _extend.quotes.isEmpty,
              hasFailed: _extend.hasNoPrices,
              errorTitle: 'We couldn’t load extension prices',
              onRetry: _extend.retry,
              skeletonCount: 4,
              skeletonHeight: 68,
              builder: (context) => _options(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _options() {
    return Column(
      spacing: SangaSpacing.md,
      children: [for (final minutes in ExtendOptions.presetMinutes) _preset(minutes), _custom()],
    );
  }

  String? _priceOf(int minutes) {
    if (_extend.unavailable.contains(minutes)) return 'Unavailable';
    return _extend.quotes[minutes]?.added.format();
  }

  Widget _preset(int minutes) {
    return SangaOptionCard(
      leading: const SangaIconBadge(child: Icon(Icons.schedule_rounded)),
      title: ExtendOptions.presetLabel(minutes),
      value: _priceOf(minutes),
      isSelected: !_extend.isCustom.value && _extend.selected.value == minutes,
      onTap: () => _extend.quotes.containsKey(minutes) ? _extend.selectPreset(minutes) : _extend.retry(),
    );
  }

  Widget _custom() {
    final minutes = _extend.customMinutes.value;
    final isCustom = _extend.isCustom.value;
    return Column(
      spacing: SangaSpacing.md,
      children: [
        SangaOptionCard(
          leading: const SangaIconBadge(child: Icon(Icons.tune_rounded)),
          title: 'Custom hours',
          value: isCustom ? _priceOf(minutes) : null,
          isSelected: isCustom,
          onTap: _extend.selectCustom,
        ),
        if (isCustom)
          Row(
            children: [
              Expanded(child: Text(ExtendOptions.label(minutes), style: SangaTextStyles.cardTitle)),
              SangaCounter(
                value: minutes ~/ ExtendOptions.customStepMinutes,
                min: ExtendOptions.customMinMinutes ~/ ExtendOptions.customStepMinutes,
                max: ExtendOptions.customMaxMinutes ~/ ExtendOptions.customStepMinutes,
                showsValue: false,
                onChanged: (steps) => _extend.setCustom(steps * ExtendOptions.customStepMinutes),
              ),
            ],
          ),
      ],
    );
  }
}
