import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Wallet', style: SangaTextStyles.headline)),
    );
  }
}
