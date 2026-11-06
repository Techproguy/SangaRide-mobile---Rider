import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/phone_change_controller.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final _controller = Get.find<PhoneChangeController>();
  final _phone = SangaPhoneController();
  String? _localError;

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_phone.isValid) {
      return setState(() => _localError = AccountProblem.invalidPhone.message);
    }
    await _controller.sendCode(_phone.e164);
  }

  Future<bool> _verify(String code) async {
    final changed = await _controller.verify(code);
    if (!mounted) return changed;
    if (changed) {
      SangaToast.show(SangaAuthCopy.phoneUpdated, tone: SangaToastTone.success);
      context.pop();
    }
    return changed;
  }

  Future<SangaResendOutcome> _resend() async {
    await _controller.resend();
    final state = _controller.state;
    return state is PhoneCode && state.problem == null
        ? SangaResendOutcome.sent(cooldown: state.session.resendAfter)
        : const SangaResendOutcome.failed();
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
      SangaButton.primary(label: SangaAuthCopy.sendCode, isLoading: isSending, onPressed: _send),
    ];
  }

  List<Widget> _verification(PhoneCode state) {
    return [
      SangaCodeEntry(
        length: AuthController.otpLength,
        sentAt: state.session.sentAt,
        cooldown: state.session.resendAfter,
        actionLabel: SangaAuthCopy.verify,
        errorText: state.problem?.message,
        isBusy: state.isVerifying,
        onEdited: _controller.clearProblem,
        onSubmit: _verify,
        onResend: _resend,
        footer: SangaTextLink(label: SangaAuthCopy.useDifferentNumber, onPressed: _controller.editNumber),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.state;
      final code = state is PhoneCode ? state : null;
      return SangaFormLayout(
        title: code == null ? SangaAuthCopy.changeYourNumber : SangaAuthCopy.enterCode,
        subtitle: code == null
            ? SangaAuthCopy.changeNumberLead
            : SangaAuthCopy.enterCodeSentTo(AuthController.otpLength, SangaPhoneNumber.masked(code.phone)),
        children: switch (state) {
          PhoneCode() => _verification(state),
          PhoneEntry(:final problem) => _entry(problem: problem, isSending: false),
          PhoneSending() || PhoneChanged() => _entry(problem: null, isSending: true),
        },
      );
    });
  }
}
