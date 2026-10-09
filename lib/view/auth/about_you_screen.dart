import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/legal.dart';
import 'package:sanga_ride/view/auth/sign_up_steps.dart';
import 'package:sanga_ride/view/auth/widgets/sign_up_error_notice.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class AboutYouScreen extends StatefulWidget {
  const AboutYouScreen({super.key});

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen> {
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
      return setState(() => _emailError = 'Enter a valid email address');
    }
    final referral = _referral.text.trim();
    final saved = await _signUp.saveProfile(
      email: _email.text.trim(),
      birthday: _birthday,
      referralCode: referral.isEmpty ? null : referral,
    );
    if (saved && mounted) context.push(SangaRoutes.selfie);
  }

  @override
  Widget build(BuildContext context) {
    return SangaFormLayout(
      title: 'A bit about you',
      subtitle: 'For receipts and keeping your account safe',
      step: RiderSignUpStep.aboutYou.formStep,
      children: [
        SangaTextField(
          label: 'Email address',
          isRequired: true,
          hintText: 'user@gmail.com',
          controller: _email,
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => setState(() => _emailError = null),
        ),
        const SizedBox(height: SangaSpacing.xl),
        SangaBirthdayField(minimumAge: 16, isRequired: false, onPicked: (date) => _birthday = date),
        const SizedBox(height: SangaSpacing.xl),
        SangaTextField(
          label: 'Referral code (optional)',
          hintText: 'Enter a referral code',
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
                const TextSpan(text: 'By continuing, you agree to Sanga Ride’s '),
                TextSpan(text: 'Terms of Service', style: SangaTextStyles.link, recognizer: _terms),
                const TextSpan(text: ' and '),
                TextSpan(text: 'Privacy Policy', style: SangaTextStyles.link, recognizer: _privacy),
                const TextSpan(text: '.'),
              ],
            ),
            style: SangaTextStyles.fine,
          ),
        ),
        const SizedBox(height: SangaSpacing.xxl),
        const SignUpErrorNotice(),
        Obx(
          () => SangaButton.primary(
            label: 'Continue',
            isLoading: _signUp.isSaving,
            onPressed: _canContinue ? _submit : null,
          ),
        ),
      ],
    );
  }
}
