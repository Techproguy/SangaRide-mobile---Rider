import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/rider/account/notifications_controller.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/controller/rider/saved_places_controller.dart';
import 'package:sanga_ride/controller/shared/map_controller.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/router/menu_routes.dart';
import 'package:sanga_ride/core/router/places_routes.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/router/who_for_routes.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride/view/airport/airport_entry.dart';
import 'package:sanga_ride/view/delivery/send/delivery_entry.dart';
import 'package:sanga_ride/view/home/widgets/home_panel.dart';
import 'package:sanga_ride/view/home/widgets/map_top_bar.dart';
import 'package:sanga_ride/view/notifications/widgets/notification_bell.dart';
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
  final _rideFor = Get.find<RideForController>();
  final _saved = Get.find<SavedPlacesController>();
  final _map = Get.find<MapController>();
  final _notifications = Get.find<NotificationsController>();
  final _restore = Get.find<SessionRestore>();
  final _panelKey = GlobalKey();
  Set<Marker> _markers = const {};
  Worker? _placeWorker;

  @override
  void initState() {
    super.initState();
    _placeWorker = ever(_home.currentPlaceObs, (_) => _showCurrentPlace());
    _showCurrentPlace();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPanelInset());
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_notifications.reload()));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_askForLocation()));
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

  Future<void> _askForLocation() async {
    if (!mounted) return;
    await _home.askForLocation(context);
  }

  Future<void> _retryRestore() async {
    final stack = await _restore.retry();
    if (stack != null) await _restore.open(stack);
  }

  Future<void> _fixLocation() async {
    switch (_home.locationAccess) {
      case PermissionAccess.denied:
        await _home.askForLocation(context);
      case PermissionAccess.serviceOff:
        await LocationService().openLocationSettings();
      case PermissionAccess.permanentlyDenied || PermissionAccess.restricted:
        await _home.openLocationSettings();
      case PermissionAccess.granted || PermissionAccess.grantedWhileInUse:
        await _home.locate();
    }
  }

  List<Widget> _notices() {
    final access = _home.locationAccess;
    return [
      if (_restore.restoreFailed)
        SangaStaleNotice(message: 'We couldn’t check for an active trip.', retryLabel: 'Retry', onRetry: _retryRestore),
      if (!access.isUsable)
        SangaStaleNotice(
          message: access == PermissionAccess.serviceOff
              ? 'Location is off. Turn it on so drivers can find you.'
              : 'Share your location so we can start pickups where you are.',
          retryLabel: access == PermissionAccess.denied ? 'Allow' : 'Settings',
          onRetry: _fixLocation,
        ),
      if (_home.hasRefreshProblem) SangaStaleNotice(onRetry: _home.refreshHome),
    ];
  }

  Future<void> _openMenu() async {
    await context.push(MenuRoutes.menu);
    if (mounted) unawaited(_notifications.reload());
  }

  void _search({RideCategory? category}) {
    _rideFor.reset();
    _openSearch(category: category);
  }

  void _openSearch({RideCategory? category}) {
    _ride.start(pickup: _home.currentPlace, category: category);
    context.push(SangaRoutes.rideSearch);
  }

  Future<void> _bookForSomeone() async {
    final chosen = await WhoForRoutes.open(context);
    if (chosen && mounted) _openSearch();
  }

  Future<void> _setUpPlace(SavedPlaceKind kind) async {
    if (!await _saved.ensureLoaded()) {
      return SangaToast.show('We couldn’t load your saved places. Give it another go.', tone: SangaToastTone.error);
    }
    if (!mounted) return;
    final existing = _saved.book?.of(kind)?.place;
    if (existing != null) return _rideTo(existing);
    final saved = await context.push<Place>(PlacesRoutes.editOf(kind));
    if (saved != null && mounted) _rideTo(saved);
  }

  void _rideTo(Place destination) {
    _rideFor.reset();
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
                  leading: SangaMapButton.menu(onPressed: _openMenu),
                  weather: _home.weather,
                  userName: user?.displayName ?? '',
                  bell: const NotificationBell(),
                  notices: _notices(),
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
                      isLocked: _restore.isRestoring,
                      home: _home.home,
                      work: _home.work,
                      onSearch: _search,
                      onRideTo: _rideTo,
                      onSavedPlaces: () => context.push(PlacesRoutes.saved),
                      onAddPlace: _setUpPlace,
                      onDelivery: () => openDelivery(context, pickup: _home.currentPlace),
                      onBookForSomeone: _bookForSomeone,
                      onAirport: () => openAirportRides(context),
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
