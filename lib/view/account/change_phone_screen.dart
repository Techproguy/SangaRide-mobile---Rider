import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/phone_change_controller.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/auth/widgets/otp_expiry_notice.dart';
import 'package:sanga_ride/view/auth/widgets/resend_code_button.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final _controller = Get.find<PhoneChangeController>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _isExpired = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _canVerify => _code.text.length == AuthController.otpLength && !_isExpired;

  Future<void> _send() async {
    if (!SangaPhoneNumber.isValid(_phone.text)) {
      return setState(() => _localError = AccountProblem.invalidPhone.message);
    }
    await _controller.sendCode(SangaPhoneNumber.toE164(_phone.text));
  }

  Future<void> _verify() async {
    if (!_canVerify) return;
    final changed = await _controller.verify(_code.text);
    if (!mounted) return;
    if (changed) {
      Toast.success('Phone number updated');
      return context.pop();
    }
    _code.clear();
  }

  Future<void> _resend() async {
    await _controller.resend();
    if (!mounted) return;
    _code.clear();
    setState(() => _isExpired = false);
    if (_controller.state case PhoneCode(problem: null)) Toast.success('New code sent. Check your messages.');
  }

  void _useAnotherNumber() {
    _code.clear();
    setState(() => _isExpired = false);
    _controller.editNumber();
  }

  List<Widget> _entry({required AccountProblem? problem, required bool isSending}) {
    return [
      SangaPhoneField(
        controller: _phone,
        autofocus: true,
        errorText: _localError ?? problem?.message,
        onChanged: (_) {
          if (_localError != null) setState(() => _localError = null);
          _controller.clearProblem();
        },
        onSubmitted: (_) => _send(),
      ),
      const SizedBox(height: SangaSpacing.xxl),
      SangaButton.primary(label: 'Send code', isLoading: isSending, onPressed: _send),
    ];
  }

  List<Widget> _verification(PhoneCode state) {
    return [
      SangaOtpField(
        length: AuthController.otpLength,
        controller: _code,
        errorText: state.problem?.message,
        onChanged: (_) => _controller.clearProblem(),
        onCompleted: (_) => _verify(),
      ),
      const SizedBox(height: SangaSpacing.lg),
      OtpExpiryNotice(sentAt: state.sentAt, onExpired: () => setState(() => _isExpired = true)),
      const SizedBox(height: SangaSpacing.xxl),
      SangaButton.primary(label: 'Verify', isLoading: state.isVerifying, onPressed: _canVerify ? _verify : null),
      const SizedBox(height: SangaSpacing.sm),
      SangaTextLink(label: 'Use a different number', onPressed: _useAnotherNumber),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.state;
      final code = state is PhoneCode ? state : null;
      return SangaFormLayout(
        title: code == null ? 'Change your number' : 'Enter OTP',
        subtitle: code == null
            ? 'We’ll text a code to your new number to make sure it’s yours'
            : 'Enter the ${AuthController.otpLength}-digit code sent to ${SangaPhoneNumber.masked(code.phone)}',
        footer: code == null ? null : ResendCodeButton(sentAt: code.sentAt, onResend: _resend),
        children: switch (state) {
          PhoneCode() => _verification(state),
          PhoneEntry(:final problem) => _entry(problem: problem, isSending: false),
          PhoneSending() || PhoneChanged() => _entry(problem: null, isSending: true),
        },
      );
    });
  }
}
