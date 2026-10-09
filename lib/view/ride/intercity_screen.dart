import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/view/ride/widgets/booking_picker_field.dart';
import 'package:sanga_ride/view/ride/widgets/place_search_sheet.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class IntercityScreen extends StatefulWidget {
  const IntercityScreen({super.key});

  @override
  State<IntercityScreen> createState() => _IntercityScreenState();
}

class _IntercityScreenState extends State<IntercityScreen> {
  final _ride = Get.find<RideRequestController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ride.loadCatalog());
  }

  Future<void> _editPlace(RouteEdit edit) async {
    final isPickup = edit.point == RoutePoint.pickup;
    await PlaceSearchSheet.show(
      context,
      kind: isPickup ? SangaStopKind.pickup : SangaStopKind.dropoff,
      hintText: isPickup ? 'Where should we pick you up?' : 'Which city are you going to?',
      origin: _ride.pickup?.coordinates,
      onPick: (place) => _ride.applyRouteEdit(edit, place),
    );
  }

  Future<void> _pickDeparture(IntercityCatalog catalog) async {
    final earliest = BookingClock.now().add(catalog.departureLead);
    final picked = await showSangaDateTimeSheet(
      context: context,
      title: 'Departure date and time',
      minimumDate: earliest,
      maximumDate: earliest.add(catalog.bookingWindow),
      initialDateTime: _ride.scheduledAt,
    );
    if (picked != null) _ride.confirmIntercityDeparture(picked);
  }

  bool _canConfirm(IntercityCatalog catalog) {
    final departure = _ride.scheduledAt;
    return _ride.intercityIssue == null &&
        departure != null &&
        !departure.isBefore(BookingClock.now().add(catalog.departureLead));
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Intercity trip',
      footer: Obx(() {
        final catalog = _ride.readyCatalog?.intercity;
        return SangaButton.primary(
          label: 'Confirm',
          onPressed: catalog == null || !_canConfirm(catalog) ? null : () => context.push(SangaRoutes.rideOptions),
        );
      }),
      children: [
        Obx(
          () => RideOptionAsyncState(
            isLoading: _ride.catalog is CatalogLoading,
            hasFailed: _ride.catalog is CatalogFailed,
            errorTitle: 'We couldn’t load intercity cities',
            failureMessage: switch (_ride.catalog) {
              CatalogFailed(:final problem) => problem.message,
              _ => null,
            },
            onRetry: _ride.loadCatalog,
            skeletonCount: 4,
            skeletonHeight: 56,
            builder: _buildContent,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final catalog = _ride.readyCatalog?.intercity;
    if (catalog == null) return const SizedBox.shrink();
    final departure = _ride.scheduledAt;
    final isStale = departure != null && departure.isBefore(BookingClock.now().add(catalog.departureLead));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        _cities(),
        BookingPickerField(
          label: 'Departure date and time',
          hintText: 'Choose when',
          icon: Icons.event_rounded,
          value: departure == null ? null : formatRideSchedule(context, departure),
          errorText: isStale ? 'That time is too soon. Pick a later one.' : null,
          onTap: () => _pickDeparture(catalog),
        ),
        Text(
          'Intercity trips need at least ${formatRideDuration(catalog.departureLead)} notice, so we can line up the right driver.',
          style: SangaTextStyles.cardSubtitle,
        ),
      ],
    );
  }

  Widget _cities() {
    final issue = _ride.intercityIssue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        const SangaSectionHeader('Choose cities'),
        _cityRow(SangaStopKind.pickup, _ride.pickup, _ride.fromCity, const RouteEdit.pickup()),
        _cityRow(SangaStopKind.dropoff, _ride.dropoff, _ride.toCity, const RouteEdit.dropoff()),
        SangaFieldError(issue?.message),
      ],
    );
  }

  Widget _cityRow(SangaStopKind kind, Place? place, City? city, RouteEdit edit) {
    return SangaLocationRow(
      kind: kind,
      title: place?.name ?? 'Choose a place',
      subtitle: place?.address,
      isPlaceholder: place == null,
      onTap: () => _editPlace(edit),
      trailing: Text(city?.name ?? 'No city', style: SangaTextStyles.cardSubtitle),
    );
  }
}
