import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/auth/widgets/resend_code_button.dart';
import 'package:sanga_ride/view/ride/who_for/widgets/passenger_code_expiry.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PassengerOtpScreen extends StatefulWidget {
  const PassengerOtpScreen({super.key});

  @override
  State<PassengerOtpScreen> createState() => _PassengerOtpScreenState();
}

class _PassengerOtpScreenState extends State<PassengerOtpScreen> {
  final _flow = Get.find<RideForController>();
  final _code = TextEditingController();
  bool _isExpired = false;

  bool get _canVerify {
    final state = _flow.passengerState;
    return state is PassengerCodePending &&
        !state.isResending &&
        !state.needsNewCode &&
        !_isExpired &&
        _code.text.length == AuthController.otpLength;
  }

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_canVerify) return;
    final verified = await _flow.verifyPassengerCode(_code.text);
    if (!mounted) return;
    if (!verified) return _code.clear();
    final state = _flow.passengerState;
    if (state is! PassengerVerified) return;
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: 'Passenger confirmed',
      message: 'We’ll text ${state.rideFor.passenger.firstName} the trip details.',
      actionLabel: 'Continue',
    );
    if (!mounted) return;
    _flow.confirmPassenger();
    context.pop(true);
  }

  Future<void> _resend() async {
    final sent = await _flow.resendPassengerCode();
    if (!sent || !mounted) return;
    _code.clear();
    Toast.success('New code sent. Check your messages.');
    setState(() => _isExpired = false);
  }

  ({PassengerInfo info, PassengerVerification verification, String? error, bool isChecking})? _view(
    PassengerFlowState state,
  ) {
    return switch (state) {
      PassengerCodePending(:final info, :final verification, :final errorText) => (
        info: info,
        verification: verification,
        error: errorText,
        isChecking: false,
      ),
      PassengerChecking(:final info, :final verification) => (
        info: info,
        verification: verification,
        error: null,
        isChecking: true,
      ),
      PassengerVerified(:final rideFor, :final verification) => (
        info: rideFor.passenger,
        verification: verification,
        error: null,
        isChecking: true,
      ),
      PassengerIdle() || PassengerSending() || PassengerSendFailed() => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final view = _view(_flow.passengerState);
      if (view == null) return const Scaffold();
      return SangaFormLayout(
        title: 'Enter OTP',
        subtitle:
            'Enter the ${AuthController.otpLength}-digit code sent to ${SangaPhoneNumber.masked(view.info.phone)} to check this is ${view.info.firstName}’s number.',
        footer: ResendCodeButton(sentAt: view.verification.sentAt, onResend: _resend),
        children: [
          SangaOtpField(
            length: AuthController.otpLength,
            controller: _code,
            errorText: view.error,
            onChanged: (_) => _flow.clearPassengerCodeFailure(),
            onCompleted: (_) => _verify(),
          ),
          const SizedBox(height: SangaSpacing.lg),
          PassengerCodeExpiry(
            expiresAt: view.verification.expiresAt,
            onExpired: () => setState(() => _isExpired = true),
          ),
          const SizedBox(height: SangaSpacing.xxl),
          SangaButton.primary(label: 'Verify', isLoading: view.isChecking, onPressed: _canVerify ? _verify : null),
        ],
      );
    });
  }
}
