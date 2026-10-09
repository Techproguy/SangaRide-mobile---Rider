import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<PhotoSource?> showPhotoSourceSheet(BuildContext context, {String title = 'Add a package photo'}) {
  return showSangaSheet<PhotoSource>(
    context: context,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.xl, SangaSpacing.xxl, SangaSpacing.xl, SangaSpacing.xl),
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        Text(title, style: SangaTextStyles.statusTitle),
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
