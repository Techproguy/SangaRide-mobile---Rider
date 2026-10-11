import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class FareChangeNote extends StatelessWidget {
  const FareChangeNote({super.key, required this.currentTotal, required this.newTotal});

  final Money currentTotal;
  final Money newTotal;

  String get _message => newTotal == currentTotal
      ? 'Your fare stays at ${currentTotal.format()}.'
      : 'Your fare goes from ${currentTotal.format()} to ${newTotal.format()}.';

  @override
  Widget build(BuildContext context) {
    return Text(_message, textAlign: TextAlign.center, style: SangaTextStyles.tileSubtitleLarge);
  }
}
