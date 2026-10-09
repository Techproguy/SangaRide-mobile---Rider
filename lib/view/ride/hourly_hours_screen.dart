import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/view/ride/widgets/hourly_duration_options.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HourlyHoursScreen extends StatefulWidget {
  const HourlyHoursScreen({super.key});

  @override
  State<HourlyHoursScreen> createState() => _HourlyHoursScreenState();
}

class _HourlyHoursScreenState extends State<HourlyHoursScreen> {
  final _ride = Get.find<RideRequestController>();
  bool _customChosen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ride.loadCatalog());
  }

  bool _isCustom(HourlyCatalog catalog) => _customChosen || !catalog.isPreset(_ride.hours);

  void _pickPreset(int hours) {
    setState(() => _customChosen = false);
    _ride.setHours(hours);
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'How many hours?',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Confirm',
          onPressed: _ride.hourlyRate == null ? null : () => context.push(BookingRoutes.afterHours),
        ),
      ),
      children: [
        Obx(
          () => RideOptionAsyncState(
            isLoading: _ride.catalog is CatalogLoading,
            hasFailed: _ride.catalog is CatalogFailed || _ride.hourlyRate == null,
            errorTitle: 'We couldn’t load hourly prices',
            failureMessage: switch (_ride.catalog) {
              CatalogFailed(:final problem) => problem.message,
              _ => null,
            },
            onRetry: _ride.loadCatalog,
            skeletonCount: 5,
            skeletonHeight: 68,
            builder: _buildContent,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final catalog = _ride.readyCatalog?.hourly;
    final rate = _ride.hourlyRate;
    if (catalog == null || rate == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        Text(
          '${_ride.option?.name ?? 'This ride'} costs ${SangaMoney.naira(rate)} an hour.',
          style: SangaTextStyles.body,
        ),
        HourlyDurationOptions(
          catalog: catalog,
          hourlyRate: rate,
          hours: _ride.hours,
          isCustom: _isCustom(catalog),
          onPreset: _pickPreset,
          onCustom: () => setState(() => _customChosen = true),
          onHoursChanged: _ride.setHours,
        ),
        _covers(catalog),
        SangaToggleRow(
          leading: const SangaIconBadge(child: Icon(Icons.person_pin_circle_outlined)),
          title: 'Stay with me',
          subtitle: 'Your driver waits at every stop and takes you on to the next',
          value: _ride.staysWithRider,
          onChanged: _ride.setStaysWithRider,
        ),
      ],
    );
  }

  Widget _covers(HourlyCatalog catalog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.sm,
      children: [
        const Text('Your price covers', style: SangaTextStyles.cardHeading),
        for (final item in catalog.includes)
          Row(
            spacing: SangaSpacing.sm,
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: SangaColors.success),
              Expanded(child: Text(item, style: SangaTextStyles.cardSubtitle)),
            ],
          ),
        if (catalog.excludes.isNotEmpty)
          Text('Not included: ${catalog.excludes.join(', ').toLowerCase()}.', style: SangaTextStyles.cardSubtitle),
      ],
    );
  }
}
