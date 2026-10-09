import 'package:flutter/material.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PackagePhotoActions extends StatelessWidget {
  const PackagePhotoActions({
    super.key,
    required this.state,
    required this.onRetake,
    required this.onRemove,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final PackagePhotoState state;
  final VoidCallback onRetake;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SangaHandoff(
      value: state.runtimeType,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.md,
        children: switch (state) {
          PhotoNone() => [
            const _Message(
              title: 'Snap it or pick it',
              body: 'A clear photo of the package helps your driver spot it.',
            ),
          ],
          PhotoPreparing() => [const _Message(title: 'One moment', body: 'We’re shrinking it so it uploads fast.')],
          PhotoUploading() => [const _Message(title: 'Uploading', body: CommonCopy.processing)],
          PhotoUploaded() => [
            const _Message(title: 'Looking good', body: 'Your driver will see this photo.'),
            Row(
              spacing: SangaSpacing.md,
              children: [
                Expanded(
                  child: SangaButton.outline(label: 'Retake', size: SangaButtonSize.compact, onPressed: onRetake),
                ),
                Expanded(
                  child: SangaButton.muted(label: 'Remove', size: SangaButtonSize.compact, onPressed: onRemove),
                ),
              ],
            ),
          ],
          PhotoFailed(:final failure) => [
            _Message(title: failure.title, body: failure.message, isError: true),
            if (failure.opensSettings)
              SangaButton.primary(
                label: CommonCopy.openSettings,
                size: SangaButtonSize.compact,
                onPressed: onOpenSettings,
              )
            else if (failure.isRetriable && state.localPath != null)
              SangaButton.primary(label: 'Try again', size: SangaButtonSize.compact, onPressed: onRetry),
            SangaButton.outline(
              label: state.localPath == null ? 'Choose a photo' : 'Retake',
              size: SangaButtonSize.compact,
              onPressed: onRetake,
            ),
          ],
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body, this.isError = false});

  final String title;
  final String body;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.xxs,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: SangaTextStyles.cardTitle.copyWith(color: isError ? SangaColors.danger : null),
        ),
        Text(body, textAlign: TextAlign.center, style: SangaTextStyles.cardBody),
      ],
    );
  }
}
