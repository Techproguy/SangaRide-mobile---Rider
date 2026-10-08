import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

ImageProvider deliveryImageOf(String source) {
  if (source.startsWith('assets/')) return AssetImage(source);
  if (source.startsWith('http')) return NetworkImage(source);
  return FileImage(File(source));
}

class DeliveryPhoto extends StatelessWidget {
  const DeliveryPhoto({super.key, required this.source, this.aspectRatio = 4 / 3, this.onTap});

  final String? source;
  final double aspectRatio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final source = this.source;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: SangaRadii.field,
        child: ColoredBox(
          color: SangaColors.cardMuted,
          child: source == null
              ? const _MissingPhoto()
              : Semantics(
                  button: onTap != null,
                  label: 'Photo',
                  child: GestureDetector(
                    onTap: onTap,
                    child: Image(
                      image: deliveryImageOf(source),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) => const _MissingPhoto(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Icon(Icons.image_not_supported_outlined, size: 32, color: SangaColors.textMuted));
  }
}

Future<void> showDeliveryPhotoViewer(BuildContext context, String source) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close photo',
    barrierColor: SangaColors.textPrimary,
    transitionDuration: SangaMotion.quick,
    pageBuilder: (context, animation, secondaryAnimation) => _PhotoViewer(source: source),
    transitionBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: SangaMotion.fadeCurve),
      child: child,
    ),
  );
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onPhoto,
      child: Material(
        color: SangaColors.textPrimary,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image(
                  image: deliveryImageOf(source),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const _MissingPhoto(),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(SangaSpacing.gutter),
                  child: SangaCircleButton.close(onPressed: () => Navigator.of(context).pop()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
