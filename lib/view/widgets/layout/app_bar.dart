import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride/core/colors.dart';
import 'package:sanga_ride/view/widgets/buttons/inkwell.dart';

class SangaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? subtitle;
  final List<Widget>? actions;
  final bool? canPop;
  final double? height;
  final double? subtitleSpacing;
  final bool showBorder;

  const SangaAppBar(
    this.title, {
    super.key,
    this.actions,
    this.subtitle,
    this.height,
    this.subtitleSpacing,
    this.canPop,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: SangaColors.lightGray.withValues(alpha: 0.4), width: 3))
            : null,
        color: SangaColors.white,
      ),
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: canPop ?? context.canPop()
                      ? SangaInkwell(onTap: context.pop, child: Image.asset(SangaAssets.back, width: 40, height: 40))
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  flex: 4,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                  ),
                ),
                if (actions == null) const Spacer() else ...actions!,
              ],
            ),
            if (subtitle != null) ...[SizedBox(height: subtitleSpacing ?? 16), subtitle!],
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (height ?? (title.isEmpty ? 12 : 48)));
}

class SangaMinimalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool? canPop;
  final double? height;
  final bool showBorder;

  const SangaMinimalAppBar(this.title, {super.key, this.actions, this.height, this.canPop, this.showBorder = true});

  @override
  Widget build(BuildContext context) {
    final showBack = canPop ?? context.canPop();
    return Container(
      decoration: BoxDecoration(
        color: SangaColors.white,
        border: showBorder
            ? Border(bottom: BorderSide(color: SangaColors.lightGray.withValues(alpha: 0.4), width: 3))
            : null,
      ),
      padding: const EdgeInsets.only(bottom: 8, top: 24),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 32),
                child: SangaInkwell(onTap: context.pop, child: Image.asset(SangaAssets.back, width: 40, height: 40)),
              )
            else
              const SizedBox(width: 24),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ),
            ...?actions,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (height ?? 24));
}
