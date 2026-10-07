import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/constants.dart';

import 'package:sanga_ride/core/colors.dart';

class SangaButton extends StatefulWidget {
  final Function? onPressed;
  final Widget child;
  final Widget? icon;
  final double width;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color backgroundColor;
  final Color foregroundColor;
  final double bottomSpacing;
  final double horizontalSpacing;
  final double? fontSize;
  final bool isEnabled;
  final bool autoLoading;
  final bool isLoading;

  const SangaButton({
    super.key,
    required this.child,
    this.onPressed,
    this.icon,
    this.horizontalSpacing = 20,
    this.fontSize,
    this.margin,
    this.backgroundColor = SangaColors.accent,
    this.foregroundColor = SangaColors.white,
    this.width = double.infinity,
    this.bottomSpacing = 12,
    this.isEnabled = true,
    this.isLoading = false,
    this.autoLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  }) : assert(!(isLoading && autoLoading), 'autoLoading overrides isLoading');

  @override
  State<SangaButton> createState() => _SangaButtonState();
}

class _SangaButtonState extends State<SangaButton> {
  RxBool isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          widget.margin ??
          EdgeInsetsGeometry.only(
            bottom: widget.bottomSpacing,
            left: widget.horizontalSpacing,
            right: widget.horizontalSpacing,
          ),
      child: Obx(
        () => TextButton(
          onPressed: (!widget.isEnabled || widget.isLoading || isLoading.value || widget.onPressed == null)
              ? null
              : () async {
                  if (widget.autoLoading) isLoading.value = true;
                  try {
                    await widget.onPressed!();
                  } finally {
                    if (widget.autoLoading) isLoading.value = false;
                  }
                },

          style: TextButton.styleFrom(
            minimumSize: Size(widget.width, 24),
            padding: widget.padding,
            textStyle: TextStyle(
              fontSize: widget.fontSize ?? 18,
              fontWeight: FontWeight.w600,
              fontFamily: SangaConstants.fontFamily,
              letterSpacing: 0,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(24)),
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            disabledBackgroundColor: SangaColors.disabledAccent,
            disabledForegroundColor: SangaColors.accent,
          ),
          child: AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            clipBehavior: Clip.none,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,

              child: widget.isLoading || isLoading.value
                  ? SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator.adaptive(backgroundColor: SangaColors.black, strokeWidth: 2),
                    )
                  : Row(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) widget.icon!,
                        Flexible(
                          child: FittedBox(fit: BoxFit.scaleDown, child: widget.child),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
