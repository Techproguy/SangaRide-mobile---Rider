import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/view/widgets/widgets.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Text(SangaConstants.appName, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
              ),
            ),
            SangaButton(onPressed: () => context.go(SangaRoutes.home), child: const Text("Let's ride")),
          ],
        ),
      ),
    );
  }
}
