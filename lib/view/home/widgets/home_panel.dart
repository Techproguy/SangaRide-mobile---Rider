import 'package:flutter/material.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride/view/home/widgets/home_place_tile.dart';
import 'package:sanga_ride/view/home/widgets/home_service_row.dart';
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

  static const double _tallImageInset = 14;

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
          spacing: SangaSpacing.sm,
          children: [
            Expanded(child: _placeTile(SangaAssets.placeHome, 28, 'Home', home, SavedPlaceKind.home)),
            Expanded(child: _placeTile(SangaAssets.placeWork, 26, 'Work', work, SavedPlaceKind.work)),
            Expanded(
              child: HomePlaceTile(
                icon: SangaAssets.placeSaved,
                iconSize: 32,
                label: 'Saved places',
                onTap: onSavedPlaces,
              ),
            ),
          ],
        ),
        const SizedBox(height: SangaSpacing.md),
        const Divider(height: 1, thickness: 1, color: SangaColors.cardBorder),
        const SizedBox(height: SangaSpacing.md),
        HomeServiceRow(
          services: [
            HomeService(
              image: const AssetImage(AppAssets.serviceRide),
              label: 'Ride',
              isSelected: true,
              onTap: onSearch,
            ),
            HomeService(
              image: const AssetImage(AppAssets.serviceDelivery),
              label: 'Delivery',
              imageInset: _tallImageInset,
              onTap: onDelivery,
            ),
            HomeService(image: const AssetImage(AppAssets.serviceAirport), label: 'Airport rides', onTap: onAirport),
            HomeService(
              image: const AssetImage(AppAssets.serviceSomeone),
              label: 'Book for someone',
              imageInset: _tallImageInset,
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

  Widget _placeTile(String icon, double iconSize, String label, Place? place, SavedPlaceKind kind) {
    return HomePlaceTile(
      icon: icon,
      iconSize: iconSize,
      label: label,
      caption: place == null ? 'Add+' : null,
      onTap: place == null ? () => onAddPlace(kind) : () => onRideTo(place),
    );
  }
}
