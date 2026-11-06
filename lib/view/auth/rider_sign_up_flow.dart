import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show OtpPurpose, OtpSession;
import 'package:sanga_ride/view/auth/about_you_step.dart';
import 'package:sanga_ride/view/auth/details_step.dart';
import 'package:sanga_ride/view/auth/home_location_step.dart';
import 'package:sanga_ride/view/auth/selfie_step.dart';
import 'package:sanga_ride/view/auth/sign_up_steps.dart';
import 'package:sanga_ride/view/auth/verify_otp_step.dart';
import 'package:sanga_ride/view/auth/widgets/leave_sign_up.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RiderSignUpFlow extends StatefulWidget {
  const RiderSignUpFlow({super.key, required this.initial});

  final RiderSignUpStep initial;

  @override
  State<RiderSignUpFlow> createState() => _RiderSignUpFlowState();
}

class _RiderSignUpFlowState extends State<RiderSignUpFlow> {
  static const Duration _landingCap = Duration(seconds: 4);

  final _signUp = Get.find<RiderSignUpController>();
  late var _step = _entryStep(widget.initial);
  String _phone = '';
  OtpSession? _session;

  @override
  void dispose() {
    _signUp.draft = null;
    _signUp.prefill = null;
    super.dispose();
  }

  RiderSignUpStep _entryStep(RiderSignUpStep requested) {
    if (!SessionStorage.tokens.hasSession) return RiderSignUpStep.details;
    return requested.index < RiderSignUpStep.aboutYou.index ? RiderSignUpStep.aboutYou : requested;
  }

  void _goTo(RiderSignUpStep step) => setState(() => _step = step);

  void _startVerification(String phone, OtpSession session) {
    _phone = phone;
    _session = session;
    _goTo(RiderSignUpStep.verify);
  }

  Future<void> _land() async {
    await Future.wait([Get.find<UserController>().fetchMe(), Get.find<SessionRestore>().refreshQuietly()])
        .timeout(_landingCap, onTimeout: () => const []);
    if (mounted) context.go(SangaRoutes.home);
  }

  SangaStepLeading get _leading => switch (_step) {
    RiderSignUpStep.details || RiderSignUpStep.verify => SangaStepLeading.back,
    _ => SangaStepLeading.close,
  };

  bool get _returnsToDetails => _step == RiderSignUpStep.verify;

  VoidCallback? get _onBack => _returnsToDetails ? () => _goTo(RiderSignUpStep.details) : null;

  Widget _page(BuildContext context, RiderSignUpStep step) {
    final session = _session;
    return switch (step) {
      RiderSignUpStep.details => SignUpDetailsStep(onStarted: _startVerification),
      RiderSignUpStep.verify when session != null => VerifyOtpStep(
        phone: _phone,
        session: session,
        purpose: OtpPurpose.registration,
        onVerified: () => _goTo(RiderSignUpStep.aboutYou),
      ),
      RiderSignUpStep.verify => SignUpDetailsStep(onStarted: _startVerification),
      RiderSignUpStep.aboutYou => AboutYouStep(onSaved: () => _goTo(RiderSignUpStep.selfie)),
      RiderSignUpStep.selfie => SelfieStep(onPassed: () => _goTo(RiderSignUpStep.home)),
      RiderSignUpStep.home => HomeLocationStep(onFinished: _land),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SangaStepFlow<RiderSignUpStep>(
      steps: RiderSignUpStep.values,
      step: _step,
      pageBuilder: _page,
      leading: _leading,
      onBack: _onBack,
      onClose: () => confirmLeaveSignUp(context),
      backStep: _returnsToDetails ? RiderSignUpStep.details : null,
    );
  }
}
