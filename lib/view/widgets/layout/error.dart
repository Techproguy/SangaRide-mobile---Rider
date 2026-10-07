import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/colors.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/widgets/buttons/button.dart';

class ErrorScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  const ErrorScreen({super.key, this.title, this.message, this.icon, this.primaryLabel, this.onPrimary});

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon ?? Icons.signpost_outlined, size: 72, color: SangaColors.lightGray),
                const SizedBox(height: 20),
                Text(
                  title ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  message ?? "We couldn't load that page. It may have moved or no longer exists.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: SangaColors.hint, height: 1.4),
                ),
                const SizedBox(height: 28),
                SangaButton(
                  onPressed: onPrimary ?? () => context.go(SangaRoutes.home),
                  horizontalSpacing: 0,
                  bottomSpacing: 0,
                  child: Text(primaryLabel ?? 'Go home'),
                ),
                if (canGoBack) ...[
                  const SizedBox(height: 12),
                  SangaButton(
                    onPressed: context.pop,
                    horizontalSpacing: 0,
                    bottomSpacing: 0,
                    backgroundColor: SangaColors.offWhite,
                    foregroundColor: SangaColors.black,
                    child: const Text('Go back'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
