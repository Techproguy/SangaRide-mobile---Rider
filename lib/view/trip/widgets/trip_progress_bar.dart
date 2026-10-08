import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripProgressBar extends StatelessWidget {
  const TripProgressBar({super.key, required this.status, this.nextStop});

  static List<SangaTripStage> stagesFor(int? nextStop) => [
    SangaTripStage(
      Icons.directions_car_rounded,
      nextStop == null ? 'On the way to drop off' : 'On the way to stop $nextStop',
    ),
    const SangaTripStage(Icons.location_on_rounded, 'You’ve arrived at your drop off'),
    const SangaTripStage(Icons.payments_rounded, 'Payment'),
    const SangaTripStage(Icons.check_rounded, 'Trip completed'),
  ];

  static bool isShownFor(TripStatus status) => status.rank >= TripStatus.inProgress.rank;

  static int stageOf(TripStatus status) => switch (status) {
    TripStatus.arrivedDropoff => 1,
    TripStatus.paymentPending => 2,
    TripStatus.completed => 3,
    _ => 0,
  };

  final TripStatus status;
  final int? nextStop;

  @override
  Widget build(BuildContext context) => SangaTripProgress(stages: stagesFor(nextStop), current: stageOf(status));
}
