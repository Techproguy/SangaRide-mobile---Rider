import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:sanga_ride/controller/rider/place_search.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/place_search_results.dart';
import 'package:sanga_ride/view/ride/widgets/place_suggestions.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideSearchScreen extends StatefulWidget {
  const RideSearchScreen({super.key});

  @override
  State<RideSearchScreen> createState() => _RideSearchScreenState();
}

class _RideSearchScreenState extends State<RideSearchScreen> {
  final _ride = Get.find<RideRequestController>();
  final _home = Get.find<RiderHomeController>();
  final _pickupQuery = TextEditingController();
  final _dropoffQuery = TextEditingController();
  final _pickupFocus = FocusNode();
  final _dropoffFocus = FocusNode();
  late final PlaceSearch _search;
  Worker? _currentPlaceWorker;
  RoutePoint _target = RoutePoint.dropoff;

  @override
  void initState() {
    super.initState();
    final current = _home.currentPlace;
    if (_ride.pickup == null && current != null) _ride.setPickup(current);
    _search = PlaceSearch(origin: _origin);
    _currentPlaceWorker = ever(_home.currentPlaceObs, _usePickupFallback);
  }

  @override
  void dispose() {
    _currentPlaceWorker?.dispose();
    _search.dispose();
    _pickupQuery.dispose();
    _dropoffQuery.dispose();
    _pickupFocus.dispose();
    _dropoffFocus.dispose();
    super.dispose();
  }

  LatLng? get _origin => _ride.pickup?.coordinates ?? _home.currentPlace?.coordinates;

  void _usePickupFallback(Place? current) {
    if (_ride.pickup != null || current == null) return;
    _ride.setPickup(current);
    _search.origin = current.coordinates;
    setState(() {});
  }

  void _focusOn(RoutePoint target) {
    if (_target == target) return;
    final query = target == RoutePoint.pickup ? _pickupQuery : _dropoffQuery;
    final focus = target == RoutePoint.pickup ? _pickupFocus : _dropoffFocus;
    setState(() => _target = target);
    _search.search(query.text);
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
  }

  Future<void> _open(PlaceAutocomplete prediction) async {
    final place = await _search.open(prediction);
    if (!mounted) return;
    if (place == null) {
      return SangaToast.show(CommonCopy.placeLoadFailed, tone: SangaToastTone.error);
    }
    _pick(place);
  }

  void _pick(Place place) {
    final isPickup = _target == RoutePoint.pickup;
    final error = _ride.applyRouteEdit(isPickup ? const RouteEdit.pickup() : const RouteEdit.dropoff(), place);
    if (error != null) return SangaToast.show(error, tone: SangaToastTone.error);
    if (!isPickup) {
      _home.rememberPlace(place);
      return _showRoute();
    }
    _pickupQuery.clear();
    _search.origin = place.coordinates;
    if (_ride.dropoff != null) return _showRoute();
    _focusOn(RoutePoint.dropoff);
  }

  void _showRoute() {
    FocusScope.of(context).unfocus();
    context.pushReplacement(SangaRoutes.rideRoute);
  }

  Widget _pickupField() {
    final pickup = _ride.pickup;
    if (_target == RoutePoint.pickup) {
      return SangaRouteField.input(
        kind: SangaStopKind.pickup,
        controller: _pickupQuery,
        focusNode: _pickupFocus,
        hintText: 'Where should we pick you up?',
        onChanged: _search.search,
        onCleared: _search.clear,
      );
    }
    return SangaRouteField.display(
      kind: SangaStopKind.pickup,
      label: 'From',
      value: pickup?.name ?? 'Choose a pickup point',
      isPlaceholder: pickup == null,
      onTap: () => _focusOn(RoutePoint.pickup),
    );
  }

  Widget _dropoffField() {
    final dropoff = _ride.dropoff;
    if (_target == RoutePoint.dropoff) {
      return SangaRouteField.input(
        kind: SangaStopKind.dropoff,
        controller: _dropoffQuery,
        focusNode: _dropoffFocus,
        hintText: 'Where are you going?',
        onChanged: _search.search,
        onCleared: _search.clear,
      );
    }
    return SangaRouteField.display(
      kind: SangaStopKind.dropoff,
      label: 'To',
      value: dropoff?.name ?? 'Where are you going?',
      isPlaceholder: dropoff == null,
      onTap: () => _focusOn(RoutePoint.dropoff),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        backgroundColor: SangaColors.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SangaSpacing.gutter,
                  SangaSpacing.sm,
                  SangaSpacing.gutter,
                  SangaSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: SangaSpacing.sm,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SangaCircleButton.back(onPressed: context.pop),
                    ),
                    const SizedBox(height: SangaSpacing.xs),
                    _pickupField(),
                    _dropoffField(),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _search,
                  builder: (context, _) => ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      SangaSpacing.gutter,
                      SangaSpacing.md,
                      SangaSpacing.gutter,
                      SangaSpacing.xl + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      if (_search.isIdle)
                        PlaceSuggestions(
                          onPick: _pick,
                          origin: _search.origin,
                          showsCurrentLocation: _target == RoutePoint.pickup,
                        )
                      else
                        PlaceSearchResults(search: _search, onPick: _open),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
