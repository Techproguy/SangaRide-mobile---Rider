import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  Future<void> _continueWith(BuildContext context, AuthProvider provider) async {
    final signedIn = await Get.find<AuthController>().continueWith(provider);
    if (signedIn && context.mounted) context.go(SangaRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onPhoto,
      child: Scaffold(
        backgroundColor: SangaColors.textPrimary,
        body: Stack(
          children: [
            const Positioned.fill(child: SangaPhotoBackdrop.blurred(image: AssetImage(AppAssets.onboardingFares))),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(SangaSpacing.md, 0, SangaSpacing.md, SangaSpacing.md),
                child: _SlideUp(
                  child: SangaAuthChoiceSheet(
                    onClose: context.pop,
                    onLogin: () => context.push(SangaRoutes.signIn),
                    onGoogle: () => _continueWith(context, AuthProvider.google),
                    onApple: () => _continueWith(context, AuthProvider.apple),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideUp extends StatelessWidget {
  const _SlideUp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, offset, child) => FractionalTranslation(translation: Offset(0, offset * 0.6), child: child),
    );
  }
}
