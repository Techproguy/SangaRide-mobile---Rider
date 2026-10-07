import 'package:flutter/material.dart';
import 'package:sanga_ride/view/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(appBar: SangaMinimalAppBar('Profile', canPop: false), body: SizedBox.expand());
  }
}
