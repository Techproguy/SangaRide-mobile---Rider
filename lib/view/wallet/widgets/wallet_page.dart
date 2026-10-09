import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key, required this.title, required this.body, this.tabs});

  static const double _backSlot = 41;

  final String title;
  final Widget body;
  final Widget? tabs;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        backgroundColor: SangaColors.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SangaSpacing.gutter,
                  SangaSpacing.md,
                  SangaSpacing.gutter,
                  SangaSpacing.xs,
                ),
                child: Row(
                  children: [
                    const SangaCircleButton.back(),
                    Expanded(
                      child: Text(title, textAlign: TextAlign.center, style: SangaTextStyles.toolbarTitle),
                    ),
                    const SizedBox(width: _backSlot),
                  ],
                ),
              ),
              ?tabs,
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
