import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _auth = Get.find<AuthController>();
  final _phone = TextEditingController();
  String? _phoneError;

  bool get _canSubmit => SangaPhoneNumber.national(_phone.text).length >= 10;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!SangaPhoneNumber.isValid(_phone.text)) {
      setState(() => _phoneError = 'Enter a valid Nigerian phone number');
      return;
    }
    final phone = SangaPhoneNumber.toE164(_phone.text);
    final sent = await _auth.requestOtp(phone);
    if (sent && mounted) context.push(SangaRoutes.verifyOtp, extra: phone);
  }

  Future<void> _continueWith(AuthProvider provider) async {
    final signedIn = await _auth.continueWith(provider);
    if (signedIn && mounted) context.go(SangaRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return SangaFormLayout(
      title: 'Welcome back',
      titleTrailing: const SangaIcon(SangaAssets.handWave, size: 24),
      subtitle: 'Enter your phone number to continue',
      children: [
        SangaPhoneField(
          controller: _phone,
          errorText: _phoneError,
          onChanged: (_) => setState(() => _phoneError = null),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: SangaSpacing.xl),
        Obx(
          () => SangaButton.primary(
            label: 'Continue',
            isLoading: _auth.isSendingCode,
            onPressed: _canSubmit ? _submit : null,
          ),
        ),
        const SizedBox(height: SangaSpacing.xl),
        const SangaLabeledDivider('or'),
        const SizedBox(height: SangaSpacing.md),
        SangaProviderButton.google(onPressed: () => _continueWith(AuthProvider.google)),
        const SizedBox(height: SangaSpacing.xs),
        SangaProviderButton.apple(onPressed: () => _continueWith(AuthProvider.apple)),
      ],
    );
  }
}
