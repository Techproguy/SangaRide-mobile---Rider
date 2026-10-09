import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key, required this.title, required this.body, this.tabs});

  final String title;
  final Widget body;
  final Widget? tabs;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SangaPageHeader(title: title),
              ?tabs,
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
