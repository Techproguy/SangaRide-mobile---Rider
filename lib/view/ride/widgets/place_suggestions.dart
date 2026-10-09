import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/controller/rider/saved_places_controller.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/widgets/feedback/location_permission_prompt.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PlaceSuggestions extends StatelessWidget {
  const PlaceSuggestions({super.key, required this.onPick, this.origin, this.showsCurrentLocation = false});

  final ValueChanged<Place> onPick;
  final LatLng? origin;
  final bool showsCurrentLocation;

  String _subtitleOf(Place place) {
    final from = origin;
    final to = place.coordinates;
    return [if (from != null && to != null) SangaDistance.format(from.metersTo(to)), place.address].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final home = Get.find<RiderHomeController>();
    final places = Get.find<SavedPlacesController>();
    return Obx(() {
      final saved = [
        if (home.home != null) (SangaAssets.placeHome, 'Home', home.home!),
        if (home.work != null) (SangaAssets.placeWork, 'Work', home.work!),
        for (final other in places.others) (SangaAssets.placeSaved, other.label, other.place),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.xl,
        children: [
          if (showsCurrentLocation) SangaListGroup(children: [CurrentLocationRow(onPick: onPick)]),
          if (home.recent.isNotEmpty)
            SangaListGroup(
              children: [
                for (final place in home.recent)
                  Dismissible(
                    key: ValueKey(place.placeId),
                    direction: DismissDirection.endToStart,
                    background: const _RemoveBackground(),
                    onDismissed: (_) => home.forgetPlace(place),
                    child: SangaListRow.recent(
                      title: place.name,
                      subtitle: _subtitleOf(place),
                      onTap: () => onPick(place),
                    ),
                  ),
              ],
            ),
          if (saved.isNotEmpty)
            SangaListGroup(
              children: [
                for (final (icon, label, place) in saved)
                  SangaListRow.saved(
                    icon: icon,
                    title: label,
                    subtitle: _subtitleOf(place),
                    onTap: () => onPick(place),
                  ),
              ],
            ),
        ],
      );
    });
  }
}

class CurrentLocationRow extends StatefulWidget {
  const CurrentLocationRow({super.key, required this.onPick});

  final ValueChanged<Place> onPick;

  @override
  State<CurrentLocationRow> createState() => _CurrentLocationRowState();
}

class _CurrentLocationRowState extends State<CurrentLocationRow> {
  final _home = Get.find<RiderHomeController>();
  String get _subtitle {
    if (_home.isLocating) return 'Finding you…';
    return switch (_home.locationStatus) {
      LocationStatus.granted => _home.currentPlace?.address ?? 'Tap to use where you are',
      LocationStatus.serviceDisabled => 'Location is off. Tap to turn it on',
      LocationStatus.denied => 'Tap to share your location',
      LocationStatus.deniedForever => 'Location access is off. Tap to allow it',
      LocationStatus.error || null => 'Tap to use where you are',
    };
  }

  Future<void> _useCurrentLocation() async {
    final current = _home.currentPlace;
    if (_home.locationStatus == LocationStatus.granted && current != null) return widget.onPick(current);
    var status = await _home.locate();
    if (!mounted) return;
    if (status != LocationStatus.granted) {
      final retry = await LocationPermissionPrompt.show(context, status);
      if (!retry || !mounted) return;
      status = await _home.locate(requestPermission: true);
    }
    final place = _home.currentPlace;
    if (status == LocationStatus.granted && place != null && mounted) widget.onPick(place);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SangaListRow(
        leading: const Icon(Icons.near_me_rounded, size: 20, color: SangaColors.primary),
        title: 'Use my current location',
        subtitle: _subtitle,
        trailing: _home.isLocating ? SangaListRow.spinner : SangaListRow.chevron,
        onTap: _home.isLocating ? null : _useCurrentLocation,
      ),
    );
  }
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SangaColors.danger,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.lg),
      child: Text('Remove', style: SangaTextStyles.label.copyWith(color: SangaColors.onPrimary)),
    );
  }
}
