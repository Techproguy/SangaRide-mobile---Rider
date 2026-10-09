import 'package:flutter/material.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryRefusedContent extends StatelessWidget {
  const DeliveryRefusedContent({super.key, required this.refusal, required this.onHome});

  static const String fallbackNextStep = 'Your package stays with you. There’s nothing else you need to do.';

  final DeliveryRefusal refusal;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final note = refusal.note;
    return SingleChildScrollView(
      physics: SangaMotion.pagePhysics,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: SangaSpacing.md,
        children: [
          SangaStatusContent(status: SangaStatus.failure, title: refusal.reason.title, message: refusal.reason.detail),
          if (note != null && note.trim().isNotEmpty)
            Text(
              'Your driver said: “${note.trim()}”',
              textAlign: TextAlign.center,
              style: SangaTextStyles.cardSubtitle,
            ),
          Text('What happens next', style: SangaTextStyles.cardTitle),
          SangaNotice(
            message: refusal.message ?? fallbackNextStep,
            tone: SangaTone.neutral,
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: SangaSpacing.xs),
          SangaButton.primary(label: CommonCopy.backToHome, onPressed: onHome),
        ],
      ),
    );
  }
}
