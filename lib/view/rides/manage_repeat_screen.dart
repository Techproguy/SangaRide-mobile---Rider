import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';
import 'package:sanga_ride/view/rides/widgets/scheduled_actions.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ManageRepeatScreen extends StatelessWidget {
  const ManageRepeatScreen({super.key, required this.rideId});

  final String rideId;

  ScheduledRide? _rideIn(ScheduledRidesController rides) {
    final state = rides.state;
    return state is ScheduledLoaded ? state.rides.where((ride) => ride.id == rideId).firstOrNull : null;
  }

  Future<void> _cancel(BuildContext context, ScheduledRidesController rides, ScheduledRide ride) async {
    final cancelled = await cancelScheduledRide(context, rides, ride);
    if (cancelled && context.mounted) context.go(BookingRoutes.scheduledRides);
  }

  @override
  Widget build(BuildContext context) {
    final rides = Get.find<ScheduledRidesController>();
    return Obx(() {
      final ride = _rideIn(rides);
      return SangaPageLayout(
        title: 'Manage trip',
        children: [
          if (ride != null)
            Column(
              spacing: SangaSpacing.md,
              children: [
                SangaSafetyChannelRow(
                  icon: Icons.calendar_month_rounded,
                  title: 'Edit schedule',
                  subtitle: 'Change days, time or start/end date',
                  onTap: () => context.push(BookingRoutes.editRepeatOf(ride.id)),
                ),
                SangaSafetyChannelRow(
                  icon: Icons.delete_outline_rounded,
                  title: 'Cancel repeat trip',
                  subtitle: 'Stop every upcoming ride in this series',
                  tone: SangaSafetyTone.danger,
                  onTap: () => _cancel(context, rides, ride),
                ),
              ],
            ),
        ],
      );
    });
  }
}
