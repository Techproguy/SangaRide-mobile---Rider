import 'package:flutter/widgets.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripVehicleCard extends StatelessWidget {
  const TripVehicleCard({super.key, required this.trip, this.showsFeatures = false});

  final Trip trip;
  final bool showsFeatures;

  @override
  Widget build(BuildContext context) {
    final vehicle = trip.vehicle;
    return SangaVehicleInfo(
      image: trip.rideType.image,
      lines: [
        vehicle.title,
        vehicle.colourLabel,
        vehicle.plateLabel,
        if (showsFeatures && vehicle.features.isNotEmpty) vehicle.features.join(', '),
      ],
    );
  }
}
