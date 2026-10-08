import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/trip_type_icon.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripTypeScreen extends StatelessWidget {
  const TripTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = Get.find<RideRequestController>();
    return SangaPageLayout(
      title: 'What type of trip?',
      footer: SangaButton.primary(
        label: 'Confirm',
        onPressed: () => context.push(BookingRoutes.afterTripType(ride.tripType)),
      ),
      children: [
        Obx(
          () => Column(
            spacing: SangaSpacing.md,
            children: [
              for (final type in TripType.values)
                SangaOptionCard(
                  leading: SangaIconBadge(child: Icon(type.icon)),
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
