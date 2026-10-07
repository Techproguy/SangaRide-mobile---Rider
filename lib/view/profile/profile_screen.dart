import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Profile', style: SangaTextStyles.headline)),
    );
  }
}
