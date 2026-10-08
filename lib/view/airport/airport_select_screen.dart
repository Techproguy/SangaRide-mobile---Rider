import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/airport_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_async_state.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum AirportSelectMode { pickUp, dropOff }

class AirportSelectScreen extends StatefulWidget {
  const AirportSelectScreen({super.key, required this.mode});

  final AirportSelectMode mode;

  @override
  State<AirportSelectScreen> createState() => _AirportSelectScreenState();
}

class _AirportSelectScreenState extends State<AirportSelectScreen> {
  final _airport = Get.find<AirportController>();
  final _query = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _airport.loadCatalog());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _confirm() {
    final airport = _airport.draft.airport;
    if (airport == null) return;
    switch (widget.mode) {
      case AirportSelectMode.pickUp:
        context.push(BookingRoutes.afterAirportSelect);
      case AirportSelectMode.dropOff:
        Get.find<RideRequestController>().start(
          pickup: Get.find<RiderHomeController>().currentPlace,
          dropoff: airport.toPlace(),
        );
        context.pushReplacement(SangaRoutes.rideRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Select airport',
      footer: Obx(
        () => SangaButton.primary(label: 'Confirm', onPressed: _airport.draft.airport == null ? null : _confirm),
      ),
      children: [
        SangaSearchField(
          controller: _query,
          hintText: 'Search airports',
          onChanged: (value) => setState(() => _search = value),
          onCleared: () => setState(() => _search = ''),
        ),
        const SizedBox(height: SangaSpacing.lg),
        Obx(
          () => RideOptionAsyncState(
            isLoading: _airport.catalog is AirportCatalogLoading,
            hasFailed: _airport.catalog is AirportCatalogFailed,
            errorTitle: 'We couldn’t load airports',
            onRetry: _airport.loadCatalog,
            skeletonCount: 4,
            skeletonHeight: 64,
            builder: _buildLists,
          ),
        ),
      ],
    );
  }

  Widget _buildLists(BuildContext context) {
    final catalog = _airport.readyCatalog;
    if (catalog == null) return const SizedBox.shrink();
    final selectedId = _airport.draft.airport?.id;
    if (_search.trim().isNotEmpty) {
      final results = catalog.search(_search);
      if (results.isEmpty) {
        return const SangaInlineMessage(title: 'No airports found', message: 'Try another name or city.');
      }
      return _section('Results', results, selectedId);
    }
    final popular = catalog.popular;
    final others = [
      for (final airport in catalog.airports)
        if (!popular.any((candidate) => candidate.id == airport.id)) airport,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        if (popular.isNotEmpty) _section('Popular airports', popular, selectedId),
        if (others.isNotEmpty) _section('More airports', others, selectedId),
      ],
    );
  }

  Widget _section(String title, List<Airport> airports, String? selectedId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        SangaSectionHeader(title),
        SangaListGroup(
          children: [
            for (final airport in airports)
              SangaAirportRow(
                name: airport.name,
                location: airport.location,
                code: airport.iata,
                isSelected: airport.id == selectedId,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _airport.selectAirport(airport);
                },
              ),
          ],
        ),
      ],
    );
  }
}
