import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripProgressBar extends StatelessWidget {
  const TripProgressBar({super.key, required this.status});

  static const List<SangaTripStage> stages = [
    SangaTripStage(Icons.directions_car_rounded, 'On the way to drop off'),
    SangaTripStage(Icons.location_on_rounded, 'You’ve arrived at your drop off'),
    SangaTripStage(Icons.payments_rounded, 'Payment'),
    SangaTripStage(Icons.check_rounded, 'Trip completed'),
  ];

  static bool isShownFor(TripStatus status) => status.rank >= TripStatus.inProgress.rank;

  static int stageOf(TripStatus status) => switch (status) {
    TripStatus.arrivedDropoff => 1,
    TripStatus.paymentPending => 2,
    TripStatus.completed => 3,
    _ => 0,
  };

  final TripStatus status;

  @override
  Widget build(BuildContext context) => SangaTripProgress(stages: stages, current: stageOf(status));
}
