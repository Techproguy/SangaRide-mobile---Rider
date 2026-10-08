import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride/view/ride/matching/widgets/driver_photo.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/completed_header.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wrapup_amount_tile.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CompletedSummary extends StatelessWidget {
  const CompletedSummary({super.key, required this.receipt});

  final TripReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final driver = receipt.driver;
    final vehicle = receipt.vehicle;
    return Column(
      spacing: SangaSpacing.lg,
      children: [
        const CompletedHeader(),
        const Divider(height: 1, thickness: 1, color: SangaColors.cardBorder),
        SangaPersonHeader(
          name: driver.name,
          rating: driver.rating,
          photo: driver.photo,
          isVerified: driver.isVerified,
          caption: driver.ridesLabel,
        ),
        SangaVehicleInfo(
          image: receipt.category.image,
          lines: [vehicle.title, '${vehicle.colourLabel} colour', 'REG NO: ${vehicle.plateLabel}'],
        ),
        WrapUpAmountTile(label: 'Total fare', amount: receipt.total),
      ],
    );
  }
}
