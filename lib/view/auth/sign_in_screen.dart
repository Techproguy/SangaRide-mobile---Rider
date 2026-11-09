import 'package:sanga_ride/core/services/region_memory.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/auth/verify_otp_screen.dart';
import 'package:sanga_ride/view/auth/widgets/social_sign_in_flow.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show OtpNotSent, OtpPurpose, OtpSent, OtpSession, SocialProvider;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.phone});

  final String? phone;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _auth = Get.find<AuthController>();
  late final _phone = SangaPhoneController.fromE164(widget.phone);
  String? _phoneError;

  bool get _canSubmit => _phone.isComplete;

  @override
  void dispose() {
    _auth.clearPhoneError();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_auth.isSendingCode) return;
    if (!_phone.isValid) {
      setState(() => _phoneError = SangaAuthCopy.invalidPhone);
      return;
    }
    final phone = _phone.e164;
    final result = await _auth.requestOtp(phone, purpose: OtpPurpose.login);
    final session = switch (result) {
      OtpSent(:final session) => session,
      OtpNotSent(:final resendIn?) => OtpSession.fromData(null).restartedAfter(resendIn),
      OtpNotSent() => null,
    };
    if (session == null || !mounted) return;
    _auth.clearPhoneError();
    context.push(
      SangaRoutes.verifyOtp,
      extra: OtpArgs(phone: phone, next: SangaRoutes.home, session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SangaFormLayout(
      title: SangaAuthCopy.welcomeBack,
      titleTrailing: const SangaIcon(SangaAssets.handWave, size: 24),
      children: [
        Obx(
          () => SangaPhoneField(
            isRequired: false,
            onRegionChanged: RegionMemory.apply,
            controller: _phone,
            autofocus: true,
            errorText: _phoneError ?? _auth.phoneError ?? _auth.requestError,
            onChanged: (_) {
              _auth.clearPhoneError();
              setState(() => _phoneError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ),
        Obx(
          () => SangaReveal(
            isVisible: _auth.phoneError != null,
            child: SangaTextLink(
              label: SangaAuthCopy.createAnAccount,
              onPressed: () => SangaRouter.switchTo(context, SangaRoutes.signUp),
            ),
          ),
        ),
        const SizedBox(height: SangaSpacing.xxl),
        Obx(
          () => SangaButton.primary(
            label: SangaAuthCopy.continueLabel,
            isLoading: _auth.isSendingCode,
            onPressed: _canSubmit ? _submit : null,
          ),
        ),
        const SizedBox(height: SangaSpacing.xl),
        const SangaLabeledDivider(SangaAuthCopy.orDivider),
        const SizedBox(height: SangaSpacing.md),
        Obx(
          () => SangaProviderButton.google(
            isLoading: _auth.signingInWith == SocialProvider.google,
            onPressed: _auth.signingInWith == null ? () => SocialSignInFlow.run(context, SocialProvider.google) : null,
          ),
        ),
        const SizedBox(height: SangaSpacing.xs),
        Obx(
          () => SangaProviderButton.apple(
            isLoading: _auth.signingInWith == SocialProvider.apple,
            onPressed: _auth.signingInWith == null ? () => SocialSignInFlow.run(context, SocialProvider.apple) : null,
          ),
        ),
      ],
    );
  }
}
