import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<PhotoSource?> showPhotoSourceSheet(BuildContext context) {
  return showSangaSheet<PhotoSource>(
    context: context,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.xl, SangaSpacing.gutter, SangaSpacing.md),
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        const Text('Add a package photo', style: SangaTextStyles.title),
        SangaListGroup(
          children: [
            SangaListRow(
              leading: const SangaIconBadge(child: Icon(Icons.photo_camera_outlined)),
              title: 'Take a photo',
              subtitle: 'Use your camera',
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            SangaListRow(
              leading: const SangaIconBadge(child: Icon(Icons.photo_library_outlined)),
              title: 'Choose from gallery',
              subtitle: 'Pick one you already have',
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ],
    ),
  );
}
