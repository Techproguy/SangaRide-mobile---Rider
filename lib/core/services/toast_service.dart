import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sanga_ride/core/nav_key.dart';
import 'package:sanga_ride/core/router/router.dart';

enum ToastType { success, error, warning, info }

class Toast {
  Toast._();

  static OverlayEntry? _current;

  static DateTime? _lastErrorAt;

  static void success(String message, {Duration? duration}) => _show(message, ToastType.success, duration: duration);

  static void error(String message, {Duration? duration}) => _show(message, ToastType.error, duration: duration);

  static void warning(String message, {Duration? duration}) => _show(message, ToastType.warning, duration: duration);

  static void info(String message, {Duration? duration}) => _show(message, ToastType.info, duration: duration);

  static void dismiss() {
    _current?.remove();
    _current = null;
  }

  static void _show(String message, ToastType type, {Duration? duration}) {
    String route = '?';
    try {
      route = SangaRouter.router.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {}
    log('[Toast:${type.name}] $message (route=$route)');

    if (type == ToastType.error || type == ToastType.warning) {
      final now = DateTime.now();
      if (_lastErrorAt != null && now.difference(_lastErrorAt!) < const Duration(milliseconds: 500)) {
        return;
      }
      _lastErrorAt = now;
    }
    dismiss();

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('Toast: overlay not ready');
      return;
    }

    _current = OverlayEntry(
      builder: (_) => _ToastWidget(message: message, type: type, onDismiss: dismiss),
    );

    overlay.insert(_current!);

    Future.delayed(duration ?? const Duration(seconds: 3), dismiss);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({required this.message, required this.type, required this.onDismiss});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(duration: const Duration(milliseconds: 280), vsync: this)
    ..forward();

  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  late final Animation<double> _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ({Color bg, Color fg, IconData icon}) get _style => switch (widget.type) {
    ToastType.success => (bg: const Color(0xFF16A34A), fg: Colors.white, icon: Icons.check_circle_outline_rounded),
    ToastType.error => (bg: const Color(0xFFDC2626), fg: Colors.white, icon: Icons.error_outline_rounded),
    ToastType.warning => (bg: const Color(0xFFD97706), fg: Colors.white, icon: Icons.warning_amber_rounded),
    ToastType.info => (bg: const Color(0xFF2563EB), fg: Colors.white, icon: Icons.info_outline_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const ValueKey('toast'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: s.bg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(s.icon, color: s.fg, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(color: s.fg, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await _ctrl.reverse();
                        widget.onDismiss();
                      },
                      child: Icon(Icons.close_rounded, color: s.fg.withValues(alpha: 0.8), size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
