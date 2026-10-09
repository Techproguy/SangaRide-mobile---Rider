import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/verification_controller.dart';
import 'package:sanga_ride/core/api/mock/mock_capture.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerificationSelfieScreen extends StatelessWidget {
  const VerificationSelfieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VerificationController>();
    return SangaSelfieCheck(
      title: 'Selfie verification',
      subtitle: 'Verify your identity',
      verify: controller.verifySelfie,
      fallbackCapture: kDebugMode ? () => MockCapture.photo('Selfie') : null,
      onOpenSettings: Geolocator.openAppSettings,
      passedMessage: 'Looking good! Your selfie is saved.',
      onPassed: () => context.pop(true),
    );
  }
}
