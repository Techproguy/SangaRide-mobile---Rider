import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class FareChangeNote extends StatelessWidget {
  const FareChangeNote({super.key, required this.currentTotal, required this.newTotal});

  final int currentTotal;
  final int newTotal;

  String get _message => newTotal == currentTotal
      ? 'Your fare stays at ${SangaMoney.naira(currentTotal)}.'
      : 'Your fare goes from ${SangaMoney.naira(currentTotal)} to ${SangaMoney.naira(newTotal)}.';

  @override
  Widget build(BuildContext context) {
    return Text(_message, textAlign: TextAlign.center, style: SangaTextStyles.tileSubtitleLarge);
  }
}
