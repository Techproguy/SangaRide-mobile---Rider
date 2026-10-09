import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class LocationPermissionPrompt {
  static Future<bool> show(BuildContext context, LocationStatus status) async {
    final permissions = Get.find<PermissionCenter>();
    switch (status) {
      case LocationStatus.granted:
        return false;
      case LocationStatus.error:
        SangaToast.show(
          'We couldn’t find you just now. Try again, or search for your pickup.',
          tone: SangaToastTone.error,
        );
        return false;
      case LocationStatus.serviceDisabled:
        final accepted = await showSangaPromptSheet(
          context: context,
          icon: Icons.location_off_rounded,
          title: 'Location is off',
          message: 'Turn on location services so your driver can find you right where you are.',
          actionLabel: 'Turn on location',
        );
        if (accepted) await LocationService().openLocationSettings();
        return false;
      case LocationStatus.deniedForever:
        final accepted = await showSangaPromptSheet(
          context: context,
          icon: Icons.location_disabled_rounded,
          title: 'Location access is off',
          message: 'Let Sanga Ride use your location in Settings, so pickups start right where you stand.',
          actionLabel: CommonCopy.openSettings,
        );
        if (accepted) await permissions.openSettings();
        return false;
      case LocationStatus.denied:
        final access = await permissions.prime(PermissionKind.location, context);
        return access.isUsable;
    }
  }
}
