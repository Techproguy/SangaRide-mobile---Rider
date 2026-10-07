import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Trips', style: SangaTextStyles.headline)),
    );
  }
}
