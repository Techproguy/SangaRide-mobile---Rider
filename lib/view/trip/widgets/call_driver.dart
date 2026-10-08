import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> callDriver(BuildContext context, {required String firstName}) async {
  final controller = Get.find<TripController>();
  if (controller.isCalling.value) return;
  final navigator = Navigator.of(context);
  final sheet = showSangaSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.xl, SangaSpacing.xxl, SangaSpacing.xl, SangaSpacing.xl),
    builder: (context) => PopScope(
      canPop: false,
      child: SangaStatusContent(
        status: SangaStatus.pending,
        title: 'Connecting you to $firstName',
        message: 'One moment while we set up a private line.',
      ),
    ),
  );
  final number = await controller.startCall();
  if (navigator.mounted) navigator.pop();
  await sheet;
  if (number == null) {
    Toast.error('We couldn’t connect your call. Give it another go.');
    return;
  }
  final isLaunched = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!isLaunched) Toast.error('We couldn’t open your phone app.');
}
