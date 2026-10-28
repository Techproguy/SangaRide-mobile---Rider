import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: SangaTheme.light,
      debugShowCheckedModeBanner: false,
      home: AnnotatedRegion(
        value: SangaSystemUi.onLight,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SangaFailureMessage(
                title: 'Couldn’t start the app',
                message: 'Check your connection and try again.',
                onRetry: onRetry,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
