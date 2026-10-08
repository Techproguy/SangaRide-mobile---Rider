import 'package:flutter/material.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class LocationPermissionPrompt {
  static Future<bool> show(BuildContext context, LocationStatus status) async {
    final location = LocationService();
    switch (status) {
      case LocationStatus.granted:
        return false;
      case LocationStatus.error:
        Toast.error('We couldn’t find you just now. Try again, or search for your pickup.');
        return false;
      case LocationStatus.serviceDisabled:
        final accepted = await showSangaPromptSheet(
          context: context,
          icon: Icons.location_off_rounded,
          title: 'Location is off',
          message: 'Turn on location services so your driver can find you right where you are.',
          actionLabel: 'Turn on location',
        );
        if (accepted) await location.openLocationSettings();
        return false;
      case LocationStatus.deniedForever:
        final accepted = await showSangaPromptSheet(
          context: context,
          icon: Icons.location_disabled_rounded,
          title: 'Location access is off',
          message: 'Let Sanga Ride use your location in Settings, so pickups start right where you stand.',
          actionLabel: 'Open Settings',
        );
        if (accepted) await location.openAppSettings();
        return false;
      case LocationStatus.denied:
        return showSangaPromptSheet(
          context: context,
          icon: Icons.near_me_rounded,
          title: 'Share your location',
          message: 'We use it to set your pickup and show drivers nearby.',
          actionLabel: 'Allow location',
        );
    }
  }
}
