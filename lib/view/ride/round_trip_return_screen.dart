import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride/view/ride/widgets/booking_note.dart';
import 'package:sanga_ride/view/ride/widgets/booking_picker_field.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RoundTripReturnScreen extends StatelessWidget {
  const RoundTripReturnScreen({super.key});

  Future<void> _pickReturn(BuildContext context, RideRequestController ride) async {
    final earliest = ride.earliestReturn;
    if (earliest == null) return;
    final picked = await showSangaDateTimeSheet(
      context: context,
      title: 'Return date and time',
      minimumDate: earliest,
      maximumDate: earliest.add(ride.rules.bookingWindow),
      initialDateTime: ride.returnAt,
    );
    if (picked != null) ride.setReturnAt(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ride = Get.find<RideRequestController>();
    return SangaPageLayout(
      title: 'When are you coming back?',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Confirm',
          onPressed: ride.returnAt == null ? null : () => context.push(SangaRoutes.rideReview),
        ),
      ),
      children: [
        Obx(() {
          final departure = ride.timing == RideTiming.now ? null : ride.scheduledAt;
          final returnAt = ride.returnAt;
          final away = returnAt?.difference(ride.departureAt ?? BookingClock.now());
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.md,
            children: [
              SangaListGroup(
                children: [
                  SangaListRow(
                    leading: const Icon(Icons.arrow_upward_rounded, size: 20, color: SangaColors.primary),
                    title: 'Going out',
                    subtitle: departure == null ? 'Right now' : formatRideSchedule(context, departure),
                    onTap: null,
                    trailing: null,
                  ),
                ],
              ),
              BookingPickerField(
                label: 'Return date and time',
                hintText: 'Choose when',
                icon: Icons.event_rounded,
                value: returnAt == null ? null : formatRideSchedule(context, returnAt),
                onTap: () => _pickReturn(context, ride),
              ),
              if (away != null)
                Text('You’ll be away for about ${formatRideDuration(away)}.', style: SangaTextStyles.body),
              const BookingNote(
                message: 'Your driver will wait for you, or we’ll match you with a new driver if they can’t.',
              ),
            ],
          );
        }),
      ],
    );
  }
}
