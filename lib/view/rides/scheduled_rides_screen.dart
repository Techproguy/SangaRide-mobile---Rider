import 'package:flutter/material.dart';
import 'package:sanga_ride/view/rides/widgets/scheduled_rides_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ScheduledRidesScreen extends StatelessWidget {
  const ScheduledRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SangaPageLayout(title: 'Scheduled rides', children: [ScheduledRidesBody()]);
  }
}
