import 'package:flutter/material.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HomePanel extends StatelessWidget {
  const HomePanel({
    super.key,
    required this.home,
    required this.work,
    required this.onSearch,
    required this.onRideTo,
    required this.onSavedPlaces,
    required this.onPromo,
  });

  final Place? home;
  final Place? work;
  final VoidCallback onSearch;
  final ValueChanged<Place> onRideTo;
  final VoidCallback onSavedPlaces;
  final VoidCallback onPromo;

  @override
  Widget build(BuildContext context) {
    return SangaMapPanel(
      children: [
        SangaSearchTrigger(hint: 'Where are you going?', onTap: onSearch),
        const SizedBox(height: SangaSpacing.md),
        Row(
          spacing: SangaSpacing.md,
          children: [
            Expanded(child: _placeTile(SangaAssets.placeHome, 'Home', home)),
            Expanded(child: _placeTile(SangaAssets.placeWork, 'Work', work)),
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
            SangaServiceTile(image: const AssetImage(AppAssets.serviceDelivery), label: 'Delivery', onTap: () {}),
            SangaServiceTile(image: const AssetImage(AppAssets.serviceAirport), label: 'Airport rides', onTap: () {}),
            SangaServiceTile(
              image: const AssetImage(AppAssets.serviceSomeone),
              label: 'Book for someone',
              onTap: () {},
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

  Widget _placeTile(String icon, String label, Place? place) {
    return SangaShortcutTile(
      icon: icon,
      label: label,
      caption: place == null ? 'Add+' : null,
      onTap: place == null ? onSavedPlaces : () => onRideTo(place),
    );
  }
}
