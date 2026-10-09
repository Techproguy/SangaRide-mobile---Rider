import 'package:flutter/material.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HomePanel extends StatelessWidget {
  const HomePanel({
    super.key,
    required this.home,
    required this.work,
    required this.onSearch,
    required this.onRideTo,
    required this.onSavedPlaces,
    required this.onAddPlace,
    required this.onDelivery,
    required this.onBookForSomeone,
    required this.onAirport,
    required this.onPromo,
    this.isLocked = false,
  });

  final Place? home;
  final Place? work;
  final VoidCallback onSearch;
  final ValueChanged<Place> onRideTo;
  final VoidCallback onSavedPlaces;
  final ValueChanged<SavedPlaceKind> onAddPlace;
  final VoidCallback onDelivery;
  final VoidCallback onBookForSomeone;
  final VoidCallback onAirport;
  final VoidCallback onPromo;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isLocked,
      child: AnimatedOpacity(opacity: isLocked ? 0.6 : 1, duration: SangaMotion.quick, child: _panel()),
    );
  }

  Widget _panel() {
    return SangaMapPanel(
      children: [
        SangaSearchTrigger(hint: 'Where are you going?', onTap: onSearch),
        const SizedBox(height: SangaSpacing.md),
        Row(
          spacing: SangaSpacing.md,
          children: [
            Expanded(child: _placeTile(SangaAssets.placeHome, 'Home', home, SavedPlaceKind.home)),
            Expanded(child: _placeTile(SangaAssets.placeWork, 'Work', work, SavedPlaceKind.work)),
            Expanded(
              child: SangaShortcutTile(icon: SangaAssets.placeSaved, label: 'Saved places', onTap: onSavedPlaces),
            ),
          ],
        ),
        const SizedBox(height: SangaSpacing.md),
        const Divider(height: 1, thickness: 1, color: SangaColors.divider),
        const SizedBox(height: SangaSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SangaServiceTile(
              image: const AssetImage(AppAssets.serviceRide),
              label: 'Ride',
              isSelected: true,
              onTap: onSearch,
            ),
            SangaServiceTile(image: const AssetImage(AppAssets.serviceDelivery), label: 'Delivery', onTap: onDelivery),
            SangaServiceTile(
              image: const AssetImage(AppAssets.serviceAirport),
              label: 'Airport rides',
              onTap: onAirport,
            ),
            SangaServiceTile(
              image: const AssetImage(AppAssets.serviceSomeone),
              label: 'Book for someone',
              onTap: onBookForSomeone,
            ),
          ],
        ),
        const SizedBox(height: SangaSpacing.md),
        SangaPromoBanner(
          image: const AssetImage(AppAssets.promoLux),
          label: 'Sanga Lux, arrive in style',
          onTap: onPromo,
        ),
      ],
    );
  }

  Widget _placeTile(String icon, String label, Place? place, SavedPlaceKind kind) {
    return SangaShortcutTile(
      icon: icon,
      label: label,
      caption: place == null ? 'Add+' : null,
      onTap: place == null ? () => onAddPlace(kind) : () => onRideTo(place),
    );
  }
}
