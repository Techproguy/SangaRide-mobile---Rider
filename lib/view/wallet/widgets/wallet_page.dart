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

class WalletList extends StatelessWidget {
  const WalletList({super.key, required this.onRefresh, required this.children, this.controller});

  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      color: SangaColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          SangaSpacing.gutter,
          SangaSpacing.md,
          SangaSpacing.gutter,
          SangaSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: children,
      ),
    );
  }
}

class WalletSkeleton extends StatelessWidget {
  const WalletSkeleton({super.key, this.heights = const [112, 56, 56, 56]});

  final List<double> heights;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.md,
      children: [
        for (final height in heights)
          Container(
            height: height,
            decoration: const BoxDecoration(color: SangaColors.cardMuted, borderRadius: SangaRadii.field),
          ),
      ],
    );
  }
}
