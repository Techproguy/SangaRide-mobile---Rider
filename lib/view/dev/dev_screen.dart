import 'package:flutter/material.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DevScreen extends StatelessWidget {
  const DevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Dev tools',
      children: [
        SangaButton.outline(label: 'Run startup again', onPressed: () => SangaRouter.router.go(SangaRoutes.boot)),
      ],
    );
  }
}
