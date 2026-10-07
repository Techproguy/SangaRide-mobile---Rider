import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/core/api/mock/mock_capture.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/auth/sign_up_steps.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SelfieScreen extends StatelessWidget {
  const SelfieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signUp = Get.find<RiderSignUpController>();
    return SangaSelfieCheck(
      title: 'Quick selfie',
      subtitle: 'Verify your identity so drivers know it’s you',
      step: RiderSignUpStep.selfie.formStep,
      verify: signUp.verifySelfie,
      fallbackCapture: kDebugMode ? () => MockCapture.photo('Selfie') : null,
      onOpenSettings: Geolocator.openAppSettings,
      onPassed: () => context.push(SangaRoutes.homeLocation),
    );
  }
}
