import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/airport_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show ServerClock;
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/airport/widgets/flight_number_formatter.dart';
import 'package:sanga_ride/view/ride/widgets/booking_picker_field.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class FlightDetailsScreen extends StatefulWidget {
  const FlightDetailsScreen({super.key});

  @override
  State<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends State<FlightDetailsScreen> {
  final _airport = Get.find<AirportController>();
  late final _number = TextEditingController(text: _airport.draft.numberText);
  final _numberFocus = FocusNode();
  bool _numberTouched = false;

  @override
  void initState() {
    super.initState();
    _numberFocus.addListener(_onFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _airport.loadCatalog());
  }

  @override
  void dispose() {
    _numberFocus
      ..removeListener(_onFocus)
      ..dispose();
    _number.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_numberFocus.hasFocus && _number.text.isNotEmpty) setState(() => _numberTouched = true);
  }

  DateTime get _today {
    final airport = _airport.draft.airport;
    final now = ServerClock.instance.now();
    if (airport != null) return airport.localToday(now);
    final local = now.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  Future<void> _pickDate() async {
    final today = _today;
    final picked = await showSangaDateSheet(
      context: context,
      title: 'Arrival date',
      initialDate: _airport.draft.arrivalDate ?? today,
      firstDate: today,
      lastDate: today.add(Get.find<RideRequestController>().rules.bookingWindow),
    );
    if (picked != null) _airport.setArrivalDate(picked);
  }

  Future<void> _confirm() async {
    setState(() => _numberTouched = true);
    FocusScope.of(context).unfocus();
    if (await _airport.lookupFlight() && mounted) unawaited(context.push(BookingRoutes.afterFlightDetails));
  }

  String? _numberError(AirportDraft draft) {
    if (!_numberTouched || !draft.hasNumberIssue) return null;
    return 'Use just the digits, like 75, or the full number, like BA 75.';
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Flight details',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Confirm',
          isLoading: _airport.lookup is FlightSearching,
          onPressed: _airport.draft.query == null ? null : _confirm,
        ),
      ),
      children: [
        Obx(
          () => RideOptionAsyncState(
            isLoading: _airport.catalog is AirportCatalogLoading,
            hasFailed: _airport.catalog is AirportCatalogFailed,
            errorTitle: 'We couldn’t load airlines',
            failureMessage: switch (_airport.catalog) {
              AirportCatalogFailed(:final problem) => problem.message,
              _ => null,
            },
            onRetry: _airport.loadCatalog,
            skeletonCount: 3,
            skeletonHeight: 68,
            builder: _buildForm,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final catalog = _airport.readyCatalog;
    if (catalog == null) return const SizedBox.shrink();
    final draft = _airport.draft;
    final arrival = draft.arrivalDate;
    final lookup = _airport.lookup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        SangaSelectField<Airline>(
          label: 'Airline',
          hintText: 'Choose airline',
          icon: Icons.flight_rounded,
          value: draft.airline,
          options: [for (final airline in catalog.airlines) SangaSelectOption(airline, airline.name)],
          onChanged: _airport.selectAirline,
        ),
        SangaTextField(
          label: 'Flight number',
          hintText: 'Enter flight number, like 75',
          controller: _number,
          focusNode: _numberFocus,
          errorText: _numberError(draft),
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          inputFormatters: const [FlightNumberFormatter()],
          onChanged: _airport.setNumberText,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          prefix: switch (draft.airline) {
            final airline? => Padding(
              padding: const EdgeInsets.only(left: SangaSpacing.md),
              child: Text(airline.code, style: SangaTextStyles.input.copyWith(color: SangaColors.textMuted)),
            ),
            null => null,
          },
          trailing: const Icon(Icons.confirmation_number_outlined, color: SangaColors.textMuted),
        ),
        BookingPickerField(
          label: 'Arrival date',
          hintText: 'Choose arrival date',
          icon: Icons.calendar_today_outlined,
          value: arrival == null ? null : formatRideDate(arrival),
          onTap: _pickDate,
        ),
        if (lookup is FlightLookupFailed) SangaNotice(message: lookup.message, icon: Icons.flight_rounded),
      ],
    );
  }
}
