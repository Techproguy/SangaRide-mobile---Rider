import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, this.photoUrl, this.size = 40});

  final String name;
  final String? photoUrl;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: SangaColors.primarySoft, borderRadius: SangaRadii.digit),
      child: url == null
          ? Text(_initials, style: SangaTextStyles.label.copyWith(color: SangaColors.primary))
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  Text(_initials, style: SangaTextStyles.label.copyWith(color: SangaColors.primary)),
            ),
    );
  }
}
