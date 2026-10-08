import 'package:flutter/widgets.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/widgets/driver_photo.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripDriverHeader extends StatelessWidget {
  const TripDriverHeader({super.key, required this.driver, this.trailing});

  final OfferDriver driver;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SangaPersonHeader(
      name: driver.name,
      rating: driver.rating,
      photo: driver.photo,
      isVerified: driver.isVerified,
      caption: driver.ridesLabel,
      trailing: trailing,
    );
  }
}
