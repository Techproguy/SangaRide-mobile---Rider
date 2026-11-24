import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key, required this.title, required this.body, this.tabs, this.trailing, this.footer});

  final String title;
  final Widget body;
  final Widget? tabs;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: SangaScrollEdgeListener(
        builder: (context, edges) => Scaffold(
          appBar: SangaAppBar(title: title, trailing: trailing),
          body: Column(
            children: [
              ?tabs,
              Expanded(child: body),
              if (footer != null) SangaPinnedFooter(showDivider: edges.isScrollable, child: footer),
            ],
          ),
        ),
      ),
    );
  }
}
