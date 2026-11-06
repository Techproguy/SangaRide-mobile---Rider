import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class BookingNote extends StatelessWidget {
  const BookingNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SangaNotice(message: message, tone: SangaTone.neutral);
  }
}
