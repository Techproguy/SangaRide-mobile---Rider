import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/sos_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/safety/widgets/sos_sheet_view.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> showSosSheet({
  required BuildContext context,
  required int contactCount,
  required Duration grace,
  required String emergencyNumber,
  required VoidCallback onEnd,
  required VoidCallback onCallEmergency,
  required VoidCallback onOpenContacts,
}) {
  return showSangaSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.xl, SangaSpacing.xxl, SangaSpacing.xl, SangaSpacing.xl),
    builder: (_) => PopScope(
      canPop: false,
      child: _SosSheet(
        contactCount: contactCount,
        grace: grace,
        emergencyNumber: emergencyNumber,
        onEnd: onEnd,
        onCallEmergency: onCallEmergency,
        onOpenContacts: onOpenContacts,
      ),
    ),
  );
}

class _SosSheet extends StatefulWidget {
  const _SosSheet({
    required this.contactCount,
    required this.grace,
    required this.emergencyNumber,
    required this.onEnd,
    required this.onCallEmergency,
    required this.onOpenContacts,
  });

  final int contactCount;
  final Duration grace;
  final String emergencyNumber;
  final VoidCallback onEnd;
  final VoidCallback onCallEmergency;
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
      return SosSheetView(
        state: _shown,
        contactCount: widget.contactCount,
        grace: widget.grace,
        emergencyNumber: widget.emergencyNumber,
        onGraceComplete: () => unawaited(_sos.send()),
        onCancel: _sos.cancel,
        onRetry: () => unawaited(_sos.retry()),
        onCloseFailure: _sos.dismissFailure,
        onEnd: widget.onEnd,
        onCallEmergency: widget.onCallEmergency,
        onOpenContacts: widget.onOpenContacts,
      );
    });
  }
}
