import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SangaSpacing.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: SangaSpacing.md,
            children: [
              Text('Wrong turn', style: SangaTextStyles.headline, textAlign: TextAlign.center),
              Text(
                "This page took a detour. Let's get you back on the road.",
                style: SangaTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SangaSpacing.md),
              SangaButton.primary(label: 'Go home', onPressed: () => context.go(SangaRoutes.home)),
            ],
          ),
        ),
      ),
    );
  }
}
