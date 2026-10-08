import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/airport_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/controller/rider/rider_home_controller.dart';
import 'package:sanga_ride/core/router/booking_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/place_search_sheet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class AirportPickupScreen extends StatelessWidget {
  const AirportPickupScreen({super.key});

  static IconData _iconFor(PickupType type) => switch (type) {
    PickupType.arrivalZone => Icons.pin_drop_outlined,
    PickupType.meetGreet => Icons.badge_outlined,
  };

  Future<void> _pickDropoff(BuildContext context, RideRequestController ride) async {
    final place = await PlaceSearchSheet.show(
      context,
      kind: SangaStopKind.dropoff,
      hintText: 'Where are you going?',
      origin: ride.pickup?.coordinates,
      onPick: (place) => ride.applyRouteEdit(const RouteEdit.dropoff(), place),
    );
    if (place != null) Get.find<RiderHomeController>().rememberPlace(place);
  }

  void _confirm(BuildContext context, RideRequestController ride, AirportBooking booking) {
    ride.setAirportBooking(booking);
    context.push(BookingRoutes.afterAirportPickup);
  }

  String _subtitle(PickupType type, num? fee) {
    if (type != PickupType.meetGreet || fee != null) return type.description;
    return '${type.description}. Adds a fee, shown in your fare.';
  }

  @override
  Widget build(BuildContext context) {
    final airport = Get.find<AirportController>();
    final ride = Get.find<RideRequestController>();
    return SangaPageLayout(
      title: 'Pick up preferences',
      footer: Obx(() {
        final booking = airport.booking;
        return SangaButton.primary(
          label: 'Confirm',
          onPressed: booking == null || ride.dropoff == null ? null : () => _confirm(context, ride, booking),
        );
      }),
      children: [
        Obx(() {
          final selected = airport.draft.pickupType;
          final dropoff = ride.dropoff;
          final fee = ride.meetGreetFee;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.md,
            children: [
              for (final type in PickupType.values)
                SangaOptionCard(
                  leading: SangaIconBadge(child: Icon(_iconFor(type))),
                  title: type.label,
                  subtitle: _subtitle(type, fee),
                  value: type == PickupType.meetGreet && fee != null ? SangaMoney.naira(fee) : null,
                  isSelected: selected == type,
                  onTap: () => airport.setPickupType(type),
                ),
              const SizedBox(height: SangaSpacing.xs),
              const SangaSectionHeader('Choose your drop off location'),
              SangaLocationRow(
                kind: SangaStopKind.dropoff,
                title: dropoff?.name ?? 'Drop off location',
                subtitle: dropoff?.address ?? 'Choose your drop off point',
                isPlaceholder: dropoff == null,
                onTap: () => _pickDropoff(context, ride),
              ),
            ],
          );
        }),
      ],
    );
  }
}
