import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/controller/shared/map_controller.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/home/widgets/home_panel.dart';
import 'package:sanga_ride/view/home/widgets/map_top_bar.dart';
import 'package:sanga_ride/view/widgets/map/place_marker.dart';
import 'package:sanga_ride/view/widgets/widgets.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final _home = Get.find<RiderHomeController>();
  final _ride = Get.find<RideRequestController>();
  final _map = Get.find<MapController>();
  final _panelKey = GlobalKey();
  Set<Marker> _markers = const {};
  Worker? _placeWorker;

  @override
  void initState() {
    super.initState();
    _placeWorker = ever(_home.currentPlaceObs, (_) => _showCurrentPlace());
    _showCurrentPlace();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPanelInset());
    unawaited(_resumeActiveTrip());
  }

  Future<void> _resumeActiveTrip() async {
    final trip = await Get.find<TripController>().loadActive();
    if (!mounted || trip == null) return;
    unawaited(context.push(TripRoutes.tripOf(trip.id)));
  }

  @override
  void dispose() {
    _placeWorker?.dispose();
    super.dispose();
  }

  void _syncPanelInset() {
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) _map.camera.visibleInsets = EdgeInsets.only(top: 120, bottom: box.size.height);
  }

  Future<void> _showCurrentPlace() async {
    final place = _home.currentPlace;
    final position = place?.coordinates;
    if (place == null || position == null) return;
    final marker = await PlaceMarker.marker(
      id: 'current',
      kind: PlaceMarkerKind.current,
      position: position,
      title: place.name,
      subtitle: 'current location',
    );
    if (!mounted) return;
    setState(() => _markers = {marker});
    _map.camera.moveTo(position, zoom: 15);
  }

  void _search({RideCategory? category}) {
    _ride.start(pickup: _home.currentPlace, category: category);
    context.push(SangaRoutes.rideSearch);
  }

  void _rideTo(Place destination) {
    _ride.start(pickup: _home.currentPlace, dropoff: destination);
    context.push(SangaRoutes.rideRoute);
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<UserController>().user;
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: SangaMap(extraMarkers: _markers)),
            SafeArea(
              child: Obx(
                () => MapTopBar(
                  leading: SangaMapButton.menu(onPressed: () {}),
                  weather: _home.weather,
                  userName: user?.displayName ?? '',
                  changedCity: _home.changedCity,
                  onConfirmCity: _home.confirmCity,
                  onDeclineCity: _home.dismissCity,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _syncPanelInset());
                  return false;
                },
                child: SizeChangedLayoutNotifier(
                  child: Obx(
                    () => HomePanel(
                      key: _panelKey,
                      home: _home.home,
                      work: _home.work,
                      onSearch: _search,
                      onRideTo: _rideTo,
                      onSavedPlaces: _search,
                      onPromo: () => _search(category: RideCategory.lux),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
