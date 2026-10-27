import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/view/safety/widgets/dial_number.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> callDriver(BuildContext context, {required String firstName}) async {
  final controller = Get.find<TripController>();
  if (controller.isCalling.value) return;
  if (LiveProblem.isOffline) {
    LiveProblem.toastOffline();
    return;
  }
  final navigator = Navigator.of(context);
  var isSheetOpen = true;
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
        secondary: SangaBusyEscape(onClose: () => Navigator.of(context).pop()),
      ),
    ),
  );
  unawaited(sheet.whenComplete(() => isSheetOpen = false));
  final call = await controller.startCall();
  if (isSheetOpen && navigator.mounted) navigator.pop();
  await sheet;
  final number = call?.maskedNumber;
  if (number != null) return dialNumber(number, failureMessage: 'We couldn’t open your phone app.');
  if (call != null && call.isServerInitiated) {
    SangaToast.show('Your phone is about to ring. Pick up to talk to $firstName.', tone: SangaToastTone.success);
    return;
  }
  SangaToast.show('We couldn’t connect your call. Give it another go.', tone: SangaToastTone.error);
}
