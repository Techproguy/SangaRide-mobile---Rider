import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RatingCommentField extends StatelessWidget {
  const RatingCommentField({super.key, required this.controller, required this.onChanged, required this.isEnabled});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SangaTextArea(
      label: 'Short review',
      controller: controller,
      hintText: 'Write here...',
      maxLength: DriverRating.maxCommentLength,
      minLines: 5,
      isEnabled: isEnabled,
      onChanged: onChanged,
    );
  }
}
