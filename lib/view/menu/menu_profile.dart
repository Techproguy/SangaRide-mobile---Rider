import 'package:flutter/material.dart';
import 'package:sanga_ride/model/user_model.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MenuProfile extends StatelessWidget {
  const MenuProfile({super.key, required this.user});

  static const double _avatarSize = 64;

  final UserModel? user;

  String get _caption {
    final rider = user;
    if (rider == null) return '';
    final trips = rider.tripCount;
    return [
      if (trips > 0) trips == 1 ? '1 trip' : '$trips trips',
      if (rider.rating case final rating?) '${rating.toStringAsFixed(1)} rating',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final rider = user;
    final name = rider?.displayName ?? '';
    final avatarUrl = rider?.avatarUrl;
    final caption = _caption;
    return Row(
      spacing: SangaSpacing.md,
      children: [
        SangaAvatar(name: name, size: _avatarSize, image: avatarUrl == null ? null : NetworkImage(avatarUrl)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.xxs,
            children: [
              Text(
                name.isEmpty ? 'Welcome' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SangaTextStyles.title,
              ),
              if (caption.isNotEmpty) Text(caption, style: SangaTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}
