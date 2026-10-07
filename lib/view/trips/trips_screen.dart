import 'package:flutter/material.dart';
import 'package:sanga_ride/view/widgets/widgets.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(appBar: SangaMinimalAppBar('Trips', canPop: false), body: SizedBox.expand());
  }
}
