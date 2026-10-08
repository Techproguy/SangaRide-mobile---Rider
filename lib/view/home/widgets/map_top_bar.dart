import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MapTopBar extends StatelessWidget {
  const MapTopBar({
    super.key,
    required this.leading,
    required this.weather,
    required this.userName,
    this.changedCity,
    this.onConfirmCity,
    this.onDeclineCity,
  });

  final Widget leading;
  final Weather? weather;
  final String userName;
  final String? changedCity;
  final VoidCallback? onConfirmCity;
  final VoidCallback? onDeclineCity;

  @override
  Widget build(BuildContext context) {
    final city = changedCity;
    return Padding(
      padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.sm, SangaSpacing.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.md,
        children: [
          Row(
            children: [
              leading,
              const Spacer(),
              if (weather case final weather?) SangaWeatherChip(city: weather.city, temperature: weather.temperatureC),
              const SizedBox(width: SangaSpacing.sm),
              SangaAvatar(name: userName),
            ],
          ),
          AnimatedSize(
            duration: SangaMotion.quick,
            curve: SangaMotion.springBlock,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            child: city == null
                ? const SizedBox(width: double.infinity)
                : SangaLocationBanner(
                    message: 'Your location has changed to $city',
                    onConfirm: onConfirmCity ?? () {},
                    onDecline: onDeclineCity ?? () {},
                  ),
          ),
        ],
      ),
    );
  }
}
