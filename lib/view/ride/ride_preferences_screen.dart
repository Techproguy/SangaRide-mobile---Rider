import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_language_row.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

typedef _Preference = ({
  IconData icon,
  String title,
  String subtitle,
  bool Function(RidePreferences) read,
  RidePreferences Function(RidePreferences, bool) write,
});

class RidePreferencesScreen extends StatelessWidget {
  const RidePreferencesScreen({super.key});

  static const _divider = Divider(height: 1, thickness: 1, color: SangaColors.cardBorder);

  static const _languages = ['English', 'Yoruba', 'Igbo', 'Hausa', 'Pidgin'];

  static final List<_Preference> _toggles = [
    (
      icon: Icons.pets_rounded,
      title: 'Pet friendly',
      subtitle: 'Bring your furry friend along',
      read: (p) => p.petFriendly,
      write: (p, value) => p.copyWith(petFriendly: value),
    ),
    (
      icon: Icons.volume_off_rounded,
      title: 'Quiet ride',
      subtitle: 'Minimal conversation',
      read: (p) => p.quietRide,
      write: (p, value) => p.copyWith(quietRide: value),
    ),
    (
      icon: Icons.woman_rounded,
      title: 'Female driver',
      subtitle: 'Where available',
      read: (p) => p.femaleDriver,
      write: (p, value) => p.copyWith(femaleDriver: value),
    ),
    (
      icon: Icons.child_care_rounded,
      title: 'Child seat',
      subtitle: 'Safe seating for little ones',
      read: (p) => p.childSeat,
      write: (p, value) => p.copyWith(childSeat: value),
    ),
    (
      icon: Icons.luggage_rounded,
      title: 'Extra luggage',
      subtitle: 'Room for bags and boxes',
      read: (p) => p.extraLuggage,
      write: (p, value) => p.copyWith(extraLuggage: value),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ride = Get.find<RideRequestController>();
    return SangaPageLayout(
      title: 'Ride preferences',
      footer: SangaButton.primary(label: 'Confirm', onPressed: () => context.push(SangaRoutes.ridePricing)),
      children: [
        Obx(() {
          final preferences = ride.preferences;
          return Column(
            children: [
              for (final (index, toggle) in _toggles.indexed) ...[
                if (index > 0) _divider,
                SangaToggleRow(
                  leading: SangaIconBadge(child: Icon(toggle.icon)),
                  title: toggle.title,
                  subtitle: toggle.subtitle,
                  value: toggle.read(preferences),
                  onChanged: (value) => ride.updatePreferences(toggle.write(preferences, value)),
                ),
              ],
              _divider,
              RideOptionLanguageRow(
                leading: const SangaIconBadge(child: Icon(Icons.translate_rounded)),
                title: 'Driver language',
                value: preferences.driverLanguage,
                options: _languages,
                onChanged: (language) => ride.updatePreferences(preferences.copyWith(driverLanguage: language)),
              ),
            ],
          );
        }),
      ],
    );
  }
}
