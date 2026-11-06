import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/who_for/who_for_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PassengerOtpScreen extends StatefulWidget {
  const PassengerOtpScreen({super.key});

  @override
  State<PassengerOtpScreen> createState() => _PassengerOtpScreenState();
}

class _PassengerOtpScreenState extends State<PassengerOtpScreen> {
  final _flow = Get.find<RideForController>();

  Future<bool> _verify(String code) async {
    final verified = await _flow.verifyPassengerCode(code);
    if (!mounted || !verified) return verified;
    final state = _flow.passengerState;
    if (state is! PassengerVerified) return verified;
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: WhoForCopy.passengerConfirmed,
      message: WhoForCopy.textTripDetails(state.rideFor.passenger.firstName),
      actionLabel: SangaAuthCopy.continueLabel,
    );
    if (!mounted) return verified;
    _flow.confirmPassenger();
    context.pop(true);
    return verified;
  }

  Future<SangaResendOutcome> _resend() async {
    final sent = await _flow.resendPassengerCode();
    final state = _flow.passengerState;
    final cooldown = state is PassengerCodePending ? state.verification.resendAfter : null;
    return sent ? SangaResendOutcome.sent(cooldown: cooldown) : const SangaResendOutcome.failed();
  }

  ({PassengerInfo info, PassengerVerification verification, String? error, bool isChecking, bool isLocked})? _view(
    PassengerFlowState state,
  ) {
    return switch (state) {
      PassengerCodePending(
        :final info,
        :final verification,
        :final errorText,
        :final isResending,
        :final needsNewCode,
      ) =>
        (
          info: info,
          verification: verification,
          error: errorText,
          isChecking: false,
          isLocked: isResending || needsNewCode,
        ),
      PassengerChecking(:final info, :final verification) => (
        info: info,
        verification: verification,
        error: null,
        isChecking: true,
        isLocked: false,
      ),
      PassengerVerified(:final rideFor, :final verification) => (
        info: rideFor.passenger,
        verification: verification,
        error: null,
        isChecking: true,
        isLocked: false,
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
        title: SangaAuthCopy.enterCode,
        subtitle: WhoForCopy.passengerCodeLead(
          AuthController.otpLength,
          SangaPhoneNumber.masked(view.info.phone),
          view.info.firstName,
        ),
        children: [
          SangaCodeEntry(
            length: AuthController.otpLength,
            sentAt: view.verification.sentAt,
            cooldown: view.verification.resendAfter,
            actionLabel: SangaAuthCopy.verify,
            errorText: view.error,
            isBusy: view.isChecking,
            isLocked: view.isLocked,
            onEdited: _flow.clearPassengerCodeFailure,
            onSubmit: _verify,
            onResend: _resend,
          ),
        ],
      );
    });
  }
}
