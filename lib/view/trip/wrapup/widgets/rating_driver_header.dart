import 'package:flutter/material.dart';
import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride/view/ride/matching/widgets/driver_photo.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RatingDriverHeader extends StatelessWidget {
  const RatingDriverHeader({super.key, required this.driver});

  static const double _avatarSize = 96;

  final OfferDriver driver;

  String get _initials {
    final parts = driver.name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final photo = driver.photo;
    return Column(
      spacing: SangaSpacing.lg,
      children: [
        Container(
          width: _avatarSize,
          height: _avatarSize,
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: SangaColors.primarySoft, shape: BoxShape.circle),
          child: photo == null
              ? Text(_initials, style: SangaTextStyles.title.copyWith(color: SangaColors.primary))
              : Image(image: photo, width: _avatarSize, height: _avatarSize, fit: BoxFit.cover),
        ),
        Text.rich(
          TextSpan(
            text: 'How was your ride with ',
            children: [
              TextSpan(text: driver.name, style: SangaTextStyles.bodyStrong),
              const TextSpan(text: '?'),
            ],
          ),
          textAlign: TextAlign.center,
          style: SangaTextStyles.body.copyWith(color: SangaColors.textPrimary),
        ),
      ],
    );
  }
}
