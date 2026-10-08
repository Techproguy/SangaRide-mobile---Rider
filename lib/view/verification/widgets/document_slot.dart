import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DocumentSlot extends StatelessWidget {
  const DocumentSlot({
    super.key,
    required this.label,
    required this.state,
    required this.onPick,
    required this.onRemove,
    required this.onRetry,
    required this.onOpenSettings,
  });

  static const double _thumbnail = 56;

  final String label;
  final PackagePhotoState state;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  Widget _thumb(String path) {
    return ClipRRect(
      borderRadius: SangaRadii.digit,
      child: Image.file(File(path), width: _thumbnail, height: _thumbnail, fit: BoxFit.cover),
    );
  }

  Widget _card({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SangaColors.surface,
        borderRadius: SangaRadii.field,
        border: Border.all(color: SangaColors.cardBorder),
      ),
      child: Padding(padding: const EdgeInsets.all(SangaSpacing.sm), child: child),
    );
  }

  Widget _uploading(PhotoUploading uploading) {
    return _card(
      child: Row(
        spacing: SangaSpacing.md,
        children: [
          _thumb(uploading.path),
          Expanded(
            child: SangaUploadProgress(progress: uploading.progress, label: 'Uploading $label'),
          ),
        ],
      ),
    );
  }

  Widget _uploaded(PhotoUploaded uploaded) {
    return _card(
      child: Row(
        spacing: SangaSpacing.md,
        children: [
          _thumb(uploaded.path),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SangaSpacing.xxs,
              children: [
                Text(label, style: SangaTextStyles.cardTitle),
                const SangaTag.success(label: 'Uploaded'),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Replace $label',
            onPressed: onPick,
            icon: const Icon(Icons.autorenew_rounded, color: SangaColors.primary),
          ),
          IconButton(
            tooltip: 'Remove $label',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: SangaColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _failed(PhotoFailed failed) {
    final problem = VerificationProblem.fromPhoto(failed.failure);
    final path = failed.localPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        SangaNotice(message: problem.message),
        if (problem.opensSettings)
          SangaButton.primary(label: 'Open Settings', size: SangaButtonSize.compact, onPressed: onOpenSettings)
        else if (failed.failure.isRetriable && path != null)
          SangaButton.primary(label: 'Try again', size: SangaButtonSize.compact, onPressed: onRetry),
        SangaButton.outline(
          label: path == null ? 'Choose a photo' : 'Choose another',
          size: SangaButtonSize.compact,
          onPressed: onPick,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SangaHandoff(
      value: state.runtimeType,
      child: switch (state) {
        PhotoNone() => SangaUploadTile(label: label, onTap: onPick),
        PhotoPreparing() => SangaUploadTile(label: label, onTap: onPick, isLoading: true),
        final PhotoUploading uploading => _uploading(uploading),
        final PhotoUploaded uploaded => _uploaded(uploaded),
        final PhotoFailed failed => _failed(failed),
      },
    );
  }
}
