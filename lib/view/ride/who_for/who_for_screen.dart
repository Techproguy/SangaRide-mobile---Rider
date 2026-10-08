import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/core/router/who_for_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WhoForScreen extends StatefulWidget {
  const WhoForScreen({super.key});

  @override
  State<WhoForScreen> createState() => _WhoForScreenState();
}

class _WhoForScreenState extends State<WhoForScreen> {
  final _flow = Get.find<RideForController>();
  late RideForKind _kind = _flow.rideFor.kind;

  static IconData _iconFor(RideForKind kind) => switch (kind) {
    RideForKind.me => Icons.person_rounded,
    RideForKind.family => Icons.groups_rounded,
    RideForKind.someone => Icons.person_outline_rounded,
    RideForKind.business => Icons.apartment_rounded,
  };

  String? _subtitleFor(RideForKind kind) {
    final current = _flow.rideFor;
    if (kind != RideForKind.me && current.kind == kind) return current.summary;
    return kind.description;
  }

  void _confirm() {
    switch (_kind) {
      case RideForKind.me:
        _flow.select(const RideForMe());
        context.pop(true);
      case RideForKind.family:
        WhoForRoutes.continueTo(context, WhoForRoutes.family);
      case RideForKind.someone:
        WhoForRoutes.continueTo(context, WhoForRoutes.passenger);
      case RideForKind.business:
        WhoForRoutes.continueTo(context, WhoForRoutes.business);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Who is this ride for?',
      footer: SangaButton.primary(label: 'Confirm', onPressed: _confirm),
      children: [
        Column(
          spacing: SangaSpacing.md,
          children: [
            for (final kind in RideForKind.values)
              SangaOptionCard(
                leading: SangaIconBadge(child: Icon(_iconFor(kind))),
                title: kind.label,
                subtitle: _subtitleFor(kind),
                isSelected: _kind == kind,
                onTap: () => setState(() => _kind = kind),
              ),
          ],
        ),
      ],
    );
  }
}
