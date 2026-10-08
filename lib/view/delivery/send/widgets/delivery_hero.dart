import 'package:flutter/material.dart';
import 'package:sanga_ride/core/assets.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryHero extends StatelessWidget {
  const DeliveryHero({super.key});

  static const double _size = 132;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _size,
        height: _size,
        decoration: const BoxDecoration(color: SangaColors.primaryWash, shape: BoxShape.circle),
        child: ClipOval(
          child: Image.asset(AppAssets.packagePhoto, width: _size, height: _size, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
