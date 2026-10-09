import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/verification_controller.dart';
import 'package:sanga_ride/core/api/mock/mock_capture.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerificationSelfieScreen extends StatefulWidget {
  const VerificationSelfieScreen({super.key});

  @override
  State<VerificationSelfieScreen> createState() => _VerificationSelfieScreenState();
}

class _VerificationSelfieScreenState extends State<VerificationSelfieScreen> {
  final _controller = Get.find<VerificationController>();
  final _permissions = Get.find<PermissionCenter>();
  bool _isPrimed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prime());
  }

  Future<void> _prime() async {
    if (!mounted) return;
    await _permissions.prime(PermissionKind.camera, context);
    if (mounted) setState(() => _isPrimed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPrimed) return const Scaffold(backgroundColor: SangaColors.surface);
    return SangaSelfieCheck(
      title: 'Selfie verification',
      subtitle: 'Verify your identity',
      verify: _controller.verifySelfie,
      fallbackCapture: kDebugMode ? () => MockCapture.photo('Selfie') : null,
      onOpenSettings: _permissions.openSettings,
      passedMessage: 'Looking good! Your selfie is saved.',
      onPassed: () => context.pop(true),
    );
  }
}
