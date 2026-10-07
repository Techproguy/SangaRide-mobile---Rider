import 'package:flutter/material.dart';
import 'package:sanga_ride/view/widgets/widgets.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(appBar: SangaMinimalAppBar('Wallet', canPop: false), body: SizedBox.expand());
  }
}
