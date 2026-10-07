import 'package:flutter/material.dart';
import 'package:sanga_ride/view/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(appBar: SangaMinimalAppBar('Home', canPop: false), body: SizedBox.expand());
  }
}
