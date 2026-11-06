import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ValueWarning extends StatelessWidget {
  const ValueWarning({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SangaNotice(title: title, message: message);
  }
}
