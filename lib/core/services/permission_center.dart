import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import 'package:sanga_ride/core/storage_keys.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show AppLifecycle;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum PermissionKind { location, camera, photos, notifications }

enum PermissionAccess { granted, grantedWhileInUse, denied, permanentlyDenied, restricted, serviceOff }

extension PermissionAccessX on PermissionAccess {
  bool get isUsable => this == PermissionAccess.granted || this == PermissionAccess.grantedWhileInUse;

  bool get canAskAgain => this == PermissionAccess.denied;

  bool get needsSettings =>
      this == PermissionAccess.permanentlyDenied ||
      this == PermissionAccess.restricted ||
      this == PermissionAccess.serviceOff;
}

class PermissionPrimer {
  const PermissionPrimer({required this.icon, required this.title, required this.message, required this.actionLabel});

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
}

class PermissionCenter extends GetxService {
  static const Map<PermissionKind, PermissionPrimer> primers = {
    PermissionKind.location: PermissionPrimer(
      icon: Icons.location_on_outlined,
      title: 'Let’s find you',
      message: 'Share your location so your driver knows exactly where to pick you up.',
      actionLabel: 'Share location',
    ),
    PermissionKind.camera: PermissionPrimer(
      icon: Icons.photo_camera_outlined,
      title: 'Smile for the camera',
      message: 'We use your camera for your selfie, your ID and package photos.',
      actionLabel: 'Allow camera',
    ),
    PermissionKind.photos: PermissionPrimer(
      icon: Icons.photo_library_outlined,
      title: 'Pick a photo',
      message: 'Let us open your photos so you can choose the right picture.',
      actionLabel: 'Allow photos',
    ),
    PermissionKind.notifications: PermissionPrimer(
      icon: Icons.notifications_none_rounded,
      title: 'Stay in the loop',
      message: 'Get a nudge when your driver is close and when your trip needs you.',
      actionLabel: 'Turn on',
    ),
  };

  final GetStorage _box = GetStorage();
  final Map<PermissionKind, Rx<PermissionAccess>> _statuses = {
    for (final kind in PermissionKind.values) kind: PermissionAccess.denied.obs,
  };
  StreamSubscription<void>? _resumeSubscription;

  Rx<PermissionAccess> statusRx(PermissionKind kind) => _statuses[kind]!;

  PermissionAccess accessOf(PermissionKind kind) => statusRx(kind).value;

  @override
  void onInit() {
    super.onInit();
    _resumeSubscription = AppLifecycle.instance.onResume.listen((_) => unawaited(refreshAll()));
    unawaited(refreshAll());
  }

  @override
  void onClose() {
    _resumeSubscription?.cancel();
    super.onClose();
  }

  Future<void> refreshAll() async {
    for (final kind in PermissionKind.values) {
      await check(kind);
    }
  }

  Future<PermissionAccess> check(PermissionKind kind) async {
    final access = await _read(kind);
    statusRx(kind).value = access;
    return access;
  }

  Future<PermissionAccess> prime(PermissionKind kind, BuildContext context) async {
    final current = await check(kind);
    if (!current.canAskAgain || !context.mounted) return current;
    if (!_wasPrimed(kind)) {
      final primer = primers[kind]!;
      final accepted = await showSangaPromptSheet(
        context: context,
        icon: primer.icon,
        title: primer.title,
        message: primer.message,
        actionLabel: primer.actionLabel,
      );
      if (!accepted) return current;
      await _box.write('$SangaStorageKeys.permissionPrimedPrefix${kind.name}', true);
    }
    return request(kind);
  }

  Future<PermissionAccess> offer(PermissionKind kind, BuildContext context) async {
    final offeredKey = '$SangaStorageKeys.permissionOfferedPrefix${kind.name}';
    if (_box.read<bool>(offeredKey) ?? false) return check(kind);
    await _box.write(offeredKey, true);
    if (!context.mounted) return check(kind);
    return prime(kind, context);
  }

  Future<PermissionAccess> request(PermissionKind kind) async {
    await _ask(kind);
    return check(kind);
  }

  Future<void> openSettings() async {
    await handler.openAppSettings();
  }

  bool _wasPrimed(PermissionKind kind) =>
      _box.read<bool>('$SangaStorageKeys.permissionPrimedPrefix${kind.name}') ?? false;

  Future<void> _ask(PermissionKind kind) async {
    switch (kind) {
      case PermissionKind.location:
        await Geolocator.requestPermission();
      case PermissionKind.camera:
        await handler.Permission.camera.request();
      case PermissionKind.photos:
        await handler.Permission.photos.request();
      case PermissionKind.notifications:
        await handler.Permission.notification.request();
    }
  }

  Future<PermissionAccess> _read(PermissionKind kind) {
    return switch (kind) {
      PermissionKind.location => _readLocation(),
      PermissionKind.camera => _readHandler(handler.Permission.camera),
      PermissionKind.photos => _readHandler(handler.Permission.photos),
      PermissionKind.notifications => _readHandler(handler.Permission.notification),
    };
  }

  Future<PermissionAccess> _readLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      final isRestricted = await handler.Permission.locationWhenInUse.status.isRestricted;
      return isRestricted ? PermissionAccess.restricted : PermissionAccess.permanentlyDenied;
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
      return PermissionAccess.denied;
    }
    if (!await Geolocator.isLocationServiceEnabled()) return PermissionAccess.serviceOff;
    return permission == LocationPermission.always ? PermissionAccess.granted : PermissionAccess.grantedWhileInUse;
  }

  Future<PermissionAccess> _readHandler(handler.Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited || status.isProvisional) return PermissionAccess.granted;
    if (status.isPermanentlyDenied) return PermissionAccess.permanentlyDenied;
    if (status.isRestricted) return PermissionAccess.restricted;
    return PermissionAccess.denied;
  }
}
