import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/controller/shared/user_controller.dart';
import 'package:sanga_ride/core/services/legal.dart';
import 'package:sanga_ride/view/auth/widgets/leave_sign_up.dart';
import 'package:sanga_ride/view/auth/widgets/sign_up_error_notice.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride/view/auth/sign_up_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class AboutYouStep extends StatefulWidget {
  const AboutYouStep({super.key, required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<AboutYouStep> createState() => _AboutYouStepState();
}

class _AboutYouStepState extends State<AboutYouStep> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _signUp = Get.find<RiderSignUpController>();
  final _email = TextEditingController();
  final _referral = TextEditingController();
  late final _terms = TapGestureRecognizer()..onTap = () => openSangaLegal(context, SangaLegal.terms);
  late final _privacy = TapGestureRecognizer()..onTap = () => openSangaLegal(context, SangaLegal.privacy);
  DateTime? _birthday;
  String? _emailError;
  var _hasAgreed = false;

  bool get _canContinue => _email.text.trim().isNotEmpty && _hasAgreed;

  @override
  void initState() {
    super.initState();
    _email.text = Get.find<UserController>().user?.email ?? _signUp.prefill?.email ?? '';
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _referral.dispose();
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_signUp.isSaving) return;
    if (!_emailPattern.hasMatch(_email.text.trim())) {
      return setState(() => _emailError = SangaAuthCopy.validEmail);
    }
    final referral = _referral.text.trim();
    final saved = await _signUp.saveProfile(
      email: _email.text.trim(),
      birthday: _birthday,
      referralCode: referral.isEmpty ? null : referral,
    );
    if (saved && mounted) widget.onSaved();
  }

  void _signInInstead() {
    final phone = _signUp.draft?.phone ?? Get.find<UserController>().user?.phone;
    unawaited(confirmLeaveSignUp(context, phone: phone));
  }

  @override
  Widget build(BuildContext context) {
    return SangaStepPage(
      title: SignUpCopy.aboutYou,
      subtitle: SignUpCopy.aboutYouSubtitle,
      children: [
        Obx(
          () => SangaTextField(
            label: SangaAuthCopy.emailAddress,
            isRequired: true,
            hintText: SignUpCopy.emailHint,
            controller: _email,
            errorText: _emailError ?? _signUp.emailError,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) {
              _signUp.clearEmailError();
              setState(() => _emailError = null);
            },
          ),
        ),
        Obx(
          () => SangaReveal(
            isVisible: _signUp.emailError != null,
            child: SangaTextLink(label: SangaAuthCopy.signInInstead, onPressed: _signInInstead),
          ),
        ),
        const SizedBox(height: SangaSpacing.xl),
        SangaBirthdayField(
          minimumAge: ServerConfig.current.minimumRiderAge,
          isRequired: false,
          onPicked: (date) => _birthday = date,
        ),
        const SizedBox(height: SangaSpacing.xl),
        SangaTextField(
          label: SignUpCopy.referralCode,
          controller: _referral,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: SangaSpacing.xl),
        SangaCheckRow(
          isChecked: _hasAgreed,
          onChanged: (value) => setState(() => _hasAgreed = value),
          label: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: SignUpCopy.agreePrefix),
                TextSpan(text: SignUpCopy.termsOfService, style: SangaTextStyles.link, recognizer: _terms),
                const TextSpan(text: SignUpCopy.and),
                TextSpan(text: SignUpCopy.privacyPolicy, style: SangaTextStyles.link, recognizer: _privacy),
                const TextSpan(text: SignUpCopy.sentenceEnd),
              ],
            ),
            style: SangaTextStyles.fine,
          ),
        ),
        const SignUpErrorNotice(),
        Obx(
          () => SangaButton.primary(
            label: SangaAuthCopy.continueLabel,
            isLoading: _signUp.isSaving,
            onPressed: _canContinue ? _submit : null,
          ),
        ),
      ],
    );
  }
}
