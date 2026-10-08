import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripTypeScreen extends StatelessWidget {
  const TripTypeScreen({super.key});

  static IconData _iconFor(TripType type) => switch (type) {
    TripType.oneWay => Icons.arrow_upward_rounded,
    _ => Icons.swap_vert_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final ride = Get.find<RideRequestController>();
    return SangaPageLayout(
      title: 'What type of trip?',
      footer: SangaButton.primary(label: 'Confirm', onPressed: () => context.push(SangaRoutes.rideOptions)),
      children: [
        Obx(
          () => Column(
            spacing: SangaSpacing.md,
            children: [
              for (final type in TripType.values)
                SangaOptionCard(
                  leading: SangaIconBadge(child: Icon(_iconFor(type))),
                  title: type.label,
                  subtitle: type.description,
                  isSelected: ride.tripType == type,
                  onTap: () => ride.setTripType(type),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
