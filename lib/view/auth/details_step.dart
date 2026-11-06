import 'package:sanga_ride/core/services/region_memory.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show OtpSession;
import 'package:sanga_ride/view/auth/widgets/sign_up_error_notice.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _Field { firstName, lastName, phone }

class SignUpDetailsStep extends StatefulWidget {
  const SignUpDetailsStep({super.key, required this.onStarted});

  final void Function(String phone, OtpSession session) onStarted;

  @override
  State<SignUpDetailsStep> createState() => _SignUpDetailsStepState();
}

class _SignUpDetailsStepState extends State<SignUpDetailsStep> {
  final _signUp = Get.find<RiderSignUpController>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = SangaPhoneController();
  var _errors = <_Field, String>{};

  @override
  void initState() {
    super.initState();
    final draft = _signUp.draft;
    if (draft == null) {
      _firstName.text = _signUp.prefill?.firstName ?? '';
      _lastName.text = _signUp.prefill?.lastName ?? '';
      return;
    }
    _firstName.text = draft.firstName;
    _lastName.text = draft.lastName;
    _phone.setE164(draft.phone);
  }

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
      if (_firstName.text.trim().isEmpty) _Field.firstName: SangaAuthCopy.addFirstName,
      if (_lastName.text.trim().isEmpty) _Field.lastName: SangaAuthCopy.addLastName,
      if (!_phone.isValid) _Field.phone: SangaAuthCopy.invalidPhone,
    };
  }

  Future<void> _submit() async {
    if (_signUp.isSaving) return;
    final errors = _validate();
    if (errors.isNotEmpty) return setState(() => _errors = errors);
    final phone = _phone.e164;
    final session = await _signUp.start(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: phone,
    );
    if (session != null && mounted) widget.onStarted(phone, session);
  }

  void _signInInstead() => SangaRouter.switchTo(context, SangaRoutes.signIn, extra: _phone.e164);

  @override
  Widget build(BuildContext context) {
    return SangaStepPage(
      title: SangaAuthCopy.letsGetStarted,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SangaSpacing.md,
          children: [
            Expanded(
              child: SangaTextField(
                label: SangaAuthCopy.firstName,
                isRequired: true,
                controller: _firstName,
                errorText: _errors[_Field.firstName],
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                onChanged: (_) => _clearError(_Field.firstName),
              ),
            ),
            Expanded(
              child: SangaTextField(
                label: SangaAuthCopy.lastName,
                isRequired: true,
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
            onRegionChanged: RegionMemory.apply,
            controller: _phone,
            errorText: _errors[_Field.phone] ?? _signUp.phoneError,
            onChanged: (_) => _clearError(_Field.phone),
            onSubmitted: (_) => _submit(),
          ),
        ),
        Obx(
          () => SangaReveal(
            isVisible: _signUp.phoneError != null,
            child: SangaTextLink(label: SangaAuthCopy.signInInstead, onPressed: _signInInstead),
          ),
        ),
        const SignUpErrorNotice(),
        Obx(
          () =>
              SangaButton.primary(label: SangaAuthCopy.continueLabel, isLoading: _signUp.isSaving, onPressed: _submit),
        ),
      ],
    );
  }
}
