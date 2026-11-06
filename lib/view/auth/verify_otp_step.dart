import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show OtpNotSent, OtpPurpose, OtpSent, OtpSession;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerifyOtpStep extends StatefulWidget {
  const VerifyOtpStep({
    super.key,
    required this.phone,
    required this.session,
    required this.purpose,
    required this.onVerified,
  });

  final String phone;
  final OtpSession session;
  final OtpPurpose purpose;
  final VoidCallback onVerified;

  @override
  State<VerifyOtpStep> createState() => _VerifyOtpStepState();
}

class _VerifyOtpStepState extends State<VerifyOtpStep> {
  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _auth.clearOtpError();
    super.dispose();
  }

  Future<bool> _verify(String code) async {
    final verified = await _auth.verifyOtp(phone: widget.phone, code: code, purpose: widget.purpose);
    if (verified && mounted) widget.onVerified();
    return verified;
  }

  Future<SangaResendOutcome> _resend() async {
    final result = await _auth.requestOtp(widget.phone, purpose: widget.purpose);
    switch (result) {
      case OtpSent(:final session):
        _auth.clearOtpError();
        return SangaResendOutcome.sent(cooldown: session.resendAfter);
      case OtpNotSent(:final message, :final resendIn):
        return SangaResendOutcome.failed(message: message, cooldown: resendIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SangaStepPage(
      title: SangaAuthCopy.enterCode,
      subtitle: SangaAuthCopy.enterCodeSentTo(AuthController.otpLength, SangaPhoneNumber.masked(widget.phone)),
      children: [
        Obx(
          () => SangaCodeEntry(
            length: AuthController.otpLength,
            sentAt: widget.session.sentAt,
            cooldown: widget.session.resendAfter,
            actionLabel: SangaAuthCopy.verify,
            errorText: _auth.otpError,
            isBusy: _auth.isVerifying,
            onEdited: _auth.clearOtpError,
            onSubmit: _verify,
            onResend: _resend,
          ),
        ),
      ],
    );
  }
}
