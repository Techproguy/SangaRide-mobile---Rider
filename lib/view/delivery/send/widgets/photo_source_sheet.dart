import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<PhotoSource?> showPhotoSourceSheet(BuildContext context, {String title = 'Add a package photo'}) {
  return showSangaOptionSheet<PhotoSource>(
    context: context,
    title: title,
    options: const [
      SangaSheetOption(
        value: PhotoSource.camera,
        icon: Icons.photo_camera_outlined,
        title: 'Take a photo',
        subtitle: 'Use your camera',
      ),
      SangaSheetOption(
        value: PhotoSource.gallery,
        icon: Icons.photo_library_outlined,
        title: 'Choose from gallery',
        subtitle: 'Pick one you already have',
      ),
    ],
  );
}
