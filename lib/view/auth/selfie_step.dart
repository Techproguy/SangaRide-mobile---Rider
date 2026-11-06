import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/view/verification/verification_copy.dart';
import 'package:sanga_ride/view/auth/sign_up_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SelfieStep extends StatelessWidget {
  const SelfieStep({super.key, required this.onPassed});

  final VoidCallback onPassed;

  @override
  Widget build(BuildContext context) {
    final permissions = Get.find<PermissionCenter>();
    return SangaSelfieCheck(
      title: SangaAuthCopy.quickSelfie,
      subtitle: SignUpCopy.selfieSubtitle,
      header: SangaSelfieHeader.embedded,
      prepare: (context) => permissions.prime(PermissionKind.camera, context),
      verify: Get.find<RiderSignUpController>().verifySelfie,
      onOpenSettings: permissions.openSettings,
      passedMessage: VerificationCopy.selfiePassed,
      onPassed: onPassed,
    );
  }
}
