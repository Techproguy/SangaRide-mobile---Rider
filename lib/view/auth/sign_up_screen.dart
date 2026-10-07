import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/auth/sign_up_steps.dart';
import 'package:sanga_ride/view/auth/verify_otp_screen.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _Field { firstName, lastName, phone }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _signUp = Get.find<RiderSignUpController>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  var _errors = <_Field, String>{};

  @override
  void dispose() {
    _signUp.clearPhoneError();
    for (final controller in [_firstName, _lastName, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearError(_Field field) {
    if (field == _Field.phone) _signUp.clearPhoneError();
    setState(() => _errors = {..._errors}..remove(field));
  }

  Map<_Field, String> _validate() {
    return {
      if (_firstName.text.trim().isEmpty) _Field.firstName: 'Add your first name',
      if (_lastName.text.trim().isEmpty) _Field.lastName: 'Add your last name',
      if (!SangaPhoneNumber.isValid(_phone.text)) _Field.phone: 'Enter a valid Nigerian phone number',
    };
  }

  Future<void> _submit() async {
    final errors = _validate();
    if (errors.isNotEmpty) return setState(() => _errors = errors);
    final phone = SangaPhoneNumber.toE164(_phone.text);
    final started = await _signUp.start(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: phone,
    );
    if (started && mounted) {
      context.push(
        SangaRoutes.verifyOtp,
        extra: OtpArgs(phone: phone, next: SangaRoutes.aboutYou, purpose: OtpPurpose.registration),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SangaFormLayout(
      title: 'Let’s get started',
      subtitle: 'Tell us who’s riding',
      step: RiderSignUpStep.details.formStep,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SangaSpacing.md,
          children: [
            Expanded(
              child: SangaTextField(
                label: 'First name',
                isRequired: true,
                hintText: 'Enter here',
                controller: _firstName,
                errorText: _errors[_Field.firstName],
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                onChanged: (_) => _clearError(_Field.firstName),
              ),
            ),
            Expanded(
              child: SangaTextField(
                label: 'Last name',
                isRequired: true,
                hintText: 'Enter here',
                controller: _lastName,
                errorText: _errors[_Field.lastName],
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                onChanged: (_) => _clearError(_Field.lastName),
              ),
            ),
          ],
        ),
        const SizedBox(height: SangaSpacing.xl),
        Obx(
          () => SangaPhoneField(
            controller: _phone,
            errorText: _errors[_Field.phone] ?? _signUp.phoneError,
            onChanged: (_) => _clearError(_Field.phone),
            onSubmitted: (_) => _submit(),
          ),
        ),
        Obx(
          () => _signUp.phoneError == null
              ? const SizedBox.shrink()
              : SangaTextLink(label: 'Log in instead', onPressed: () => context.pushReplacement(SangaRoutes.signIn)),
        ),
        const SizedBox(height: SangaSpacing.xxl),
        Obx(() => SangaButton.primary(label: 'Continue', isLoading: _signUp.isSaving, onPressed: _submit)),
      ],
    );
  }
}
