import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/core/router/who_for_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideForSummaryTile extends StatelessWidget {
  const RideForSummaryTile({super.key, required this.rideFor, required this.onChange});

  final RideFor rideFor;
  final VoidCallback onChange;

  String get _subtitle => [rideFor.summary, rideFor.detail].whereType<String>().join(' · ');

  @override
  Widget build(BuildContext context) {
    return SangaInfoTile.compact(
      icon: SangaAssets.profile,
      title: 'Who’s riding',
      subtitle: _subtitle,
      actionLabel: 'Change',
      onTap: onChange,
    );
  }
}

class RideForSummaryRow extends StatelessWidget {
  const RideForSummaryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = Get.find<RideForController>();
    return Obx(() => RideForSummaryTile(rideFor: flow.rideFor, onChange: () => WhoForRoutes.open(context)));
  }
}
