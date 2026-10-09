import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/model/auth/otp_session.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class OtpArgs {
  const OtpArgs({required this.phone, required this.next, required this.purpose, required this.session});

  final String phone;
  final String next;
  final OtpPurpose purpose;
  final OtpSession session;
}

class VerifyOtpScreen extends StatefulWidget {
  VerifyOtpScreen(OtpArgs args, {super.key})
    : phone = args.phone,
      next = args.next,
      purpose = args.purpose,
      initialSession = args.session;

  final String phone;
  final String next;
  final OtpPurpose purpose;
  final OtpSession initialSession;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const Duration _landingCap = Duration(seconds: 4);

  final _auth = Get.find<AuthController>();
  final _code = TextEditingController();
  late OtpSession _session = widget.initialSession;
  bool _isExpired = false;

  bool get _canVerify => _code.text.length == AuthController.otpLength && !_isExpired;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _auth.clearOtpError();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_canVerify || _auth.isVerifying) return;
    final verified = await _auth.verifyOtp(phone: widget.phone, code: _code.text);
    if (!mounted) return;
    if (!verified) return _code.clear();
    await _land();
  }

  Future<void> _land() async {
    if (widget.purpose == OtpPurpose.registration) return context.go(widget.next);
    final restore = Get.find<SessionRestore>();
    final stack = await restore.retry().timeout(_landingCap, onTimeout: () => null);
    if (!mounted) return;
    if (stack == null) return context.go(widget.next);
    await restore.open(stack);
  }

  Future<void> _resend() async {
    final result = await _auth.requestOtp(widget.phone, purpose: widget.purpose);
    if (!mounted) return;
    switch (result) {
      case OtpNotSent(:final message):
        if (message.isNotEmpty) SangaToast.show(message, tone: SangaToastTone.error);
      case OtpSent(:final session):
        _auth.clearOtpError();
        _code.clear();
        SangaToast.show('New code sent. Check your messages.', tone: SangaToastTone.success);
        setState(() {
          _session = session;
          _isExpired = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SangaFormLayout(
      title: 'Enter OTP',
      subtitle:
          'Enter the ${AuthController.otpLength}-digit code sent to ${SangaPhoneNumber.masked(widget.phone)} to verify your account',
      footer: SangaResendCodeButton(sentAt: _session.sentAt, cooldown: _session.resendAfter, onResend: _resend),
      children: [
        Obx(
          () => SangaOtpField(
            length: AuthController.otpLength,
            controller: _code,
            errorText: _auth.otpError,
            onChanged: (_) => _auth.clearOtpError(),
            onCompleted: (_) => _verify(),
          ),
        ),
        const SizedBox(height: SangaSpacing.lg),
        SangaOtpExpiryNotice(
          sentAt: _session.sentAt,
          lifetime: _session.lifetime,
          onExpired: () => setState(() => _isExpired = true),
        ),
        const SizedBox(height: SangaSpacing.xxl),
        Obx(
          () => SangaButton.primary(
            label: 'Verify',
            isLoading: _auth.isVerifying,
            onPressed: _canVerify ? _verify : null,
          ),
        ),
      ],
    );
  }
}
