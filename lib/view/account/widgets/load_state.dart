import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: SangaSpacing.xxl),
      child: Center(child: SangaActivityIndicator(size: 36)),
    );
  }
}

class LoadFailure extends StatelessWidget {
  const LoadFailure({super.key, required this.message, required this.onRetry, this.title = 'That didn’t load'});

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SangaInlineMessage(title: title, message: message, actionLabel: 'Try again', onAction: onRetry);
  }
}
