import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryProgressBar extends StatelessWidget {
  const DeliveryProgressBar({super.key, required this.phase, this.legProgress = 0});

  static const List<SangaTripStage> stages = [
    SangaTripStage(Icons.directions_car_rounded, 'On the way to the drop off'),
    SangaTripStage(Icons.location_on_rounded, 'Your driver is at the drop off'),
    SangaTripStage(Icons.inventory_2_rounded, 'Package handed over to recipient'),
    SangaTripStage(Icons.check_rounded, 'Delivery complete'),
  ];

  static bool isShownFor(DeliveryPhase phase) =>
      phase.index >= DeliveryPhase.onTheWay.index && phase != DeliveryPhase.returning;

  final DeliveryPhase phase;
  final double legProgress;

  @override
  Widget build(BuildContext context) =>
      SangaTripProgress(stages: stages, current: phase.progressStage, legProgress: legProgress);
}
