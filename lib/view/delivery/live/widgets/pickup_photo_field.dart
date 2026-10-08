import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/live/widgets/delivery_photo.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PickupPhotoField extends StatelessWidget {
  const PickupPhotoField({
    super.key,
    required this.state,
    required this.onTake,
    required this.onRemove,
    required this.onRetryUpload,
    required this.onOpenSettings,
  });

  final DeliveryPickupState state;
  final VoidCallback onTake;
  final VoidCallback onRemove;
  final VoidCallback onRetryUpload;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final path = state.photoPath;
    return AnimatedSize(
      duration: SangaMotion.morph,
      curve: SangaMotion.springBlock,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.sm,
        children: [
          if (path == null)
            _TakePhotoTile(isPreparing: state is PickupPreparing, onTap: onTake)
          else
            _Preview(path: path, state: state, onRemove: onRemove),
          if (state case PickupPhotoFailed(:final problem))
            _Problem(
              problem: problem,
              hasPhoto: path != null,
              onRetry: onRetryUpload,
              onTake: onTake,
              onOpenSettings: onOpenSettings,
            ),
          if (path != null && !state.isBusy && state is! PickupConfirmed && state is! PickupPhotoFailed)
            SangaButton.outline(label: 'Retake photo', onPressed: onTake),
        ],
      ),
    );
  }
}

class _TakePhotoTile extends StatelessWidget {
  const _TakePhotoTile({required this.isPreparing, required this.onTap});

  static const double _height = 150;

  final bool isPreparing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take a photo of the package with your driver',
      child: CustomPaint(
        foregroundPainter: const _DashedFramePainter(),
        child: Material(
          color: SangaColors.primaryWash,
          borderRadius: SangaRadii.field,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isPreparing ? null : onTap,
            child: SizedBox(
              height: _height,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: SangaSpacing.xs,
                  children: [
                    if (isPreparing)
                      const SangaActivityIndicator(size: 36)
                    else
                      const Icon(Icons.photo_camera_outlined, size: 36, color: SangaColors.primary),
                    Text(
                      isPreparing ? 'Getting your photo ready…' : 'Tap to take photo',
                      style: SangaTextStyles.caption.copyWith(color: SangaColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.path, required this.state, required this.onRemove});

  final String path;
  final DeliveryPickupState state;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isLocked = state.isBusy || state is PickupConfirmed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        Stack(
          children: [
            DeliveryPhoto(source: path, aspectRatio: 4 / 3, onTap: () => showDeliveryPhotoViewer(context, path)),
            if (!isLocked)
              Positioned(
                top: SangaSpacing.xs,
                right: SangaSpacing.xs,
                child: SangaCircleButton.close(onPressed: onRemove),
              ),
          ],
        ),
        if (state case PickupUploading(:final progress))
          SangaUploadProgress(progress: progress, label: 'Uploading photo'),
      ],
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({
    required this.problem,
    required this.hasPhoto,
    required this.onRetry,
    required this.onTake,
    required this.onOpenSettings,
  });

  final DeliveryPickupProblem problem;
  final bool hasPhoto;
  final VoidCallback onRetry;
  final VoidCallback onTake;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final (label, action) = switch ((
      problem.opensSettings,
      hasPhoto && problem == DeliveryPickupProblem.uploadFailed,
    )) {
      (true, _) => ('Open Settings', onOpenSettings),
      (_, true) => ('Try again', onRetry),
      _ => ('Take photo', onTake),
    };
    return SangaInlineMessage(title: problem.title, message: problem.message, actionLabel: label, onAction: action);
  }
}

class _DashedFramePainter extends CustomPainter {
  const _DashedFramePainter();

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()..addRRect(SangaRadii.field.toRRect(Offset.zero & size).deflate(0.5));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = SangaColors.primary;
    for (final metric in outline.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += _dash + _gap) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedFramePainter oldDelegate) => false;
}
