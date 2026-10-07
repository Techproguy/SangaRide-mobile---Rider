import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Home', style: SangaTextStyles.headline)),
    );
  }
}
