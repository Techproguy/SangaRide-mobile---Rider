import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show OtpPurpose, OtpSession;
import 'package:sanga_ride/view/auth/verify_otp_step.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class OtpArgs {
  const OtpArgs({required this.phone, required this.next, required this.session});

  final String phone;
  final String next;
  final OtpSession session;
}

class VerifyOtpScreen extends StatelessWidget {
  const VerifyOtpScreen(this.args, {super.key});

  static const Duration _landingCap = Duration(seconds: 4);

  final OtpArgs args;

  Future<void> _land(BuildContext context) async {
    final restore = Get.find<SessionRestore>();
    final stack = await restore.retry().timeout(_landingCap, onTimeout: () => null);
    if (!context.mounted) return;
    if (stack == null) return context.go(args.next);
    await restore.open(stack);
  }

  @override
  Widget build(BuildContext context) {
    return SangaStepScaffold(
      child: VerifyOtpStep(
        phone: args.phone,
        session: args.session,
        purpose: OtpPurpose.login,
        onVerified: () => _land(context),
      ),
    );
  }
}
