import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/widgets/safety_check_row.dart';
import 'package:sanga_ride/view/trip/widgets/trip_page_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripTimelineScreen extends StatelessWidget {
  const TripTimelineScreen({super.key, required this.tripId});

  static const List<(TripEventType, IconData)> _milestones = [
    (TripEventType.driverAccepted, Icons.directions_car_rounded),
    (TripEventType.driverArrived, Icons.location_on_rounded),
    (TripEventType.tripStarted, Icons.directions_car_rounded),
    (TripEventType.arrivedDropoff, Icons.location_on_rounded),
    (TripEventType.tripCompleted, Icons.check_rounded),
  ];

  final String tripId;

  static String? _timeOf(Trip trip, TripEventType type) {
    final at = trip.eventTime(type);
    return at == null ? null : DateFormat('h:mm a').format(at);
  }

  List<SangaTimelineEntry> _entries(Trip trip) {
    return [
      for (final (type, icon) in _milestones)
        SangaTimelineEntry(title: type.label, icon: icon, time: _timeOf(trip, type), isDone: trip.hasEvent(type)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripController>();
    return TripPageGate(
      tripId: tripId,
      title: 'Trip timeline',
      child: Obx(() {
      final trip = controller.trip;
      return SangaPageLayout(
        title: 'Trip timeline',
        children: [
          if (trip == null)
            const SangaSkeleton.heights([48, 48, 48, 48])
          else ...[
            SangaTimeline(entries: _entries(trip)),
            const SizedBox(height: SangaSpacing.xl),
            Text('Safety and verification', style: SangaTextStyles.titleSmall),
            const SizedBox(height: SangaSpacing.md),
            Column(
              spacing: SangaSpacing.md,
              children: [
                SafetyCheckRow(label: 'Driver match', isConfirmed: trip.hasEvent(TripEventType.detailsConfirmed)),
                SafetyCheckRow(label: 'PIN', isConfirmed: trip.hasEvent(TripEventType.pinVerified)),
              ],
            ),
          ],
        ],
      );
    }),
    );
  }
}
