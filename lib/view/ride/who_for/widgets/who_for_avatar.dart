import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WhoForAvatar extends StatelessWidget {
  const WhoForAvatar({super.key, required this.name});

  static const double size = 40;

  final String name;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: SangaColors.primarySoft, borderRadius: SangaRadii.digit),
      child: Text(_initials, style: SangaTextStyles.label.copyWith(color: SangaColors.primary)),
    );
  }
}
