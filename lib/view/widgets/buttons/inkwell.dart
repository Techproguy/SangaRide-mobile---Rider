import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:sanga_ride/core/extensions/extensions.dart';

class SangaInkwell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double pressedOpacity;
  final Curve curve;
  final Color? color;
  final double? borderRadius;
  final bool isVisible;
  final BoxDecoration? decoration;
  final HitTestBehavior behavior;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const SangaInkwell({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.borderRadius,
    this.isVisible = true,
    this.decoration,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.duration = const Duration(milliseconds: 120),
    this.pressedOpacity = 0.75,
    this.curve = Curves.easeOut,
    this.behavior = HitTestBehavior.translucent,
  });

  @override
  State<SangaInkwell> createState() => _SangaInkwellState();
}

class _SangaInkwellState extends State<SangaInkwell> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isVisible ? widget.onTap.addLowHaptic() : null,
      child: AnimatedOpacity(
        opacity: widget.isVisible ? 1 : 0,
        duration: 300.ms,
        curve: Curves.easeOut,
        child: Container(
          padding: widget.padding,
          margin: widget.margin,
          decoration:
              widget.decoration ??
              BoxDecoration(
                color: widget.color ?? Colors.transparent,
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
              ),
          child: AnimatedOpacity(
            duration: widget.duration,
            opacity: _isPressed ? widget.pressedOpacity : 1.0,
            curve: widget.curve,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
