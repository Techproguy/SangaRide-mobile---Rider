import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<PhotoSource?> showPhotoSourceSheet(
  BuildContext context, {
  String title = 'Add a package photo',
  bool allowsFile = false,
}) {
  return showSangaOptionSheet<PhotoSource>(
    context: context,
    title: title,
    options: [
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
      if (allowsFile)
        SangaSheetOption(
          value: PhotoSource.file,
          icon: Icons.description_outlined,
          title: 'Choose a file',
          subtitle: 'PDF or image',
        ),
    ],
  );
}
