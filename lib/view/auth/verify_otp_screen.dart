import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/view/auth/widgets/otp_expiry_notice.dart';
import 'package:sanga_ride/view/auth/widgets/resend_code_button.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _auth = Get.find<AuthController>();
  final _code = TextEditingController();
  DateTime _sentAt = DateTime.now();
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
    if (verified) return context.go(SangaRoutes.home);
    _code.clear();
  }

  Future<void> _resend() async {
    final sent = await _auth.requestOtp(widget.phone);
    if (!sent || !mounted) return;
    _auth.clearOtpError();
    _code.clear();
    Toast.success('New code sent. Check your messages.');
    setState(() {
      _sentAt = DateTime.now();
      _isExpired = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SangaFormLayout(
      title: 'Enter OTP',
      subtitle:
          'Enter the ${AuthController.otpLength}-digit code sent to ${SangaPhoneNumber.masked(widget.phone)} to verify your account',
      footer: ResendCodeButton(sentAt: _sentAt, onResend: _resend),
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
        OtpExpiryNotice(sentAt: _sentAt, onExpired: () => setState(() => _isExpired = true)),
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
