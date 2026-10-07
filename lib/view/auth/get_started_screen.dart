import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/shared/auth_controller.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key, this.revealFrom});

  final String? revealFrom;

  Future<void> _continueWith(BuildContext context, AuthProvider provider) async {
    final signedIn = await Get.find<AuthController>().continueWith(provider);
    if (signedIn && context.mounted) context.go(SangaRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onPhoto,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: SangaPhotoBackdrop.blurred(
                image: const AssetImage(AppAssets.getStarted),
                revealFrom: switch (revealFrom) {
                  final path? => AssetImage(path),
                  null => null,
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(SangaSpacing.md, 0, SangaSpacing.md, SangaSpacing.md),
                child: SangaRouteRise(
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
