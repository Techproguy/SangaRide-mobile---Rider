import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/safety/sos_controller.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/safety/widgets/dial_number.dart';
import 'package:sanga_ride/view/safety/widgets/sos_sheet_view.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class SosLauncher {
  static bool _isOpen = false;

  static Future<void> start(BuildContext context, {String? tripId}) async {
    final sos = Get.find<SosController>();
    if (!sos.isIdle) return present(context);
    sos.start(tripId: tripId);
    await present(context);
  }

  static Future<void> present(BuildContext context) async {
    if (_isOpen || !context.mounted) return;
    final sos = Get.find<SosController>();
    if (sos.isIdle) return;
    _isOpen = true;
    await showSangaSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      padding: const EdgeInsets.fromLTRB(SangaSpacing.xl, SangaSpacing.xxl, SangaSpacing.xl, SangaSpacing.xl),
      builder: (sheet) => PopScope(
        canPop: false,
        child: _SosSheet(
          onEnd: () => unawaited(_confirmEnd(context)),
          onOpenContacts: () => unawaited(context.push(SafetyRoutes.contacts)),
        ),
      ),
    );
    _isOpen = false;
  }

  static Future<void> _confirmEnd(BuildContext context) async {
    final isConfirmed = await showSangaPromptSheet(
      context: context,
      icon: Icons.health_and_safety_rounded,
      title: 'End SOS?',
      message: 'Only end it if you’re safe. We’ll stop alerting and sharing your location.',
      actionLabel: 'End SOS',
      dismissLabel: 'Keep SOS on',
    );
    if (isConfirmed) await Get.find<SosController>().end();
  }
}

class _SosSheet extends StatefulWidget {
  const _SosSheet({required this.onEnd, required this.onOpenContacts});

  final VoidCallback onEnd;
  final VoidCallback onOpenContacts;

  @override
  State<_SosSheet> createState() => _SosSheetState();
}

class _SosSheetState extends State<_SosSheet> {
  final _sos = Get.find<SosController>();
  late final Worker _worker;
  late SosState _shown;

  @override
  void initState() {
    super.initState();
    _shown = _sos.state;
    _worker = ever(_sos.stateRx, _onState);
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  void _onState(SosState state) {
    if (state is SosIdle && mounted) Navigator.of(context).popUntil((route) => route is! PopupRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _sos.state;
      if (state is! SosIdle) _shown = state;
      final number = _sos.emergencyNumber;
      return SosSheetView(
        state: _shown,
        contactCount: _sos.contactCount,
        grace: _sos.grace,
        emergencyNumber: number,
        onGraceComplete: () => unawaited(_sos.send()),
        onCancel: _sos.cancel,
        onRetry: () => unawaited(_sos.retry()),
        onCloseFailure: _sos.dismissFailure,
        onEnd: widget.onEnd,
        onCallEmergency: () => unawaited(dialNumber(number)),
        onOpenContacts: widget.onOpenContacts,
      );
    });
  }
}
