import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/core/api/mock/mock_capture.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/view/auth/sign_up_steps.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SelfieScreen extends StatefulWidget {
  const SelfieScreen({super.key});

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  final _signUp = Get.find<RiderSignUpController>();
  final _permissions = Get.find<PermissionCenter>();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    await _permissions.prime(PermissionKind.camera, context);
    if (mounted) setState(() => _isReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Scaffold();
    return SangaSelfieCheck(
      title: 'Quick selfie',
      subtitle: 'Verify your identity so drivers know it’s you',
      step: RiderSignUpStep.selfie.formStep,
      verify: _signUp.verifySelfie,
      fallbackCapture: kDebugMode ? () => MockCapture.photo('Selfie') : null,
      onOpenSettings: _permissions.openSettings,
      onPassed: () => context.push(SangaRoutes.homeLocation),
      onLater: () {
        _signUp.skipSelfie();
        context.push(SangaRoutes.homeLocation);
      },
    );
  }
}
