import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/trip/trip_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_photo.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_proof_rows.dart';
import 'package:sanga_ride/view/trip/widgets/trip_page_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryProofScreen extends StatelessWidget {
  const DeliveryProofScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripController>();
    return TripPageGate(
      tripId: tripId,
      title: 'Delivery proof',
      child: Obx(() {
      final trip = controller.trip;
      final proof = trip?.delivery?.deliveryProof;
      final canComplete = trip?.deliveryPhase == DeliveryPhase.handedOver;
      return SangaPageLayout(
        title: 'Delivery proof',
        footer: canComplete
            ? SangaButton.primary(
                label: 'Complete delivery',
                isLoading: controller.isCompleting.value,
                onPressed: controller.completeRide,
              )
            : null,
        children: [
          if (trip == null)
            const SangaSkeleton.heights([220, 64, 64])
          else if (proof == null)
            const SangaInlineMessage(
              icon: Icons.hourglass_top_rounded,
              title: 'Your driver is still finishing up',
              message: 'The proof of delivery shows up here as soon as the package is handed over.',
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.xl,
              children: [
                DeliveryPhoto(
                  source: proof.photoUrl,
                  onTap: proof.photoUrl == null ? null : () => showDeliveryPhotoViewer(context, proof.photoUrl!),
                ),
                DeliveryProofRows(proof: proof, dropoff: trip.dropoff, recipient: trip.delivery!.recipient),
              ],
            ),
        ],
      );
    }),
    );
  }
}
