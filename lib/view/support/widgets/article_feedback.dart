import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ArticleFeedback extends StatelessWidget {
  const ArticleFeedback({
    super.key,
    required this.vote,
    required this.isVoting,
    required this.onVote,
    required this.onContact,
  });

  final ArticleVote vote;
  final bool isVoting;
  final ValueChanged<bool> onVote;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SangaColors.fill, borderRadius: SangaRadii.field),
      child: Padding(
        padding: const EdgeInsets.all(SangaSpacing.md),
        child: SangaHandoff(
          value: vote,
          child: switch (vote) {
            ArticleVote.none => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.sm,
              children: [
                Text('Was this helpful?', textAlign: TextAlign.center, style: SangaTextStyles.cardTitle),
                Row(
                  spacing: SangaSpacing.sm,
                  children: [
                    Expanded(
                      child: SangaButton.outline(
                        label: 'Yes',
                        size: SangaButtonSize.compact,
                        onPressed: isVoting ? null : () => onVote(true),
                      ),
                    ),
                    Expanded(
                      child: SangaButton.outline(
                        label: 'No',
                        size: SangaButtonSize.compact,
                        onPressed: isVoting ? null : () => onVote(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ArticleVote.helpful => Text(
              'Glad that helped. Thanks for telling us.',
              textAlign: TextAlign.center,
              style: SangaTextStyles.cardTitle,
            ),
            ArticleVote.notHelpful => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.sm,
              children: [
                Text(
                  'Sorry about that. Our team can help.',
                  textAlign: TextAlign.center,
                  style: SangaTextStyles.cardTitle,
                ),
                SangaButton.primary(label: 'Contact support', size: SangaButtonSize.compact, onPressed: onContact),
              ],
            ),
          },
        ),
      ),
    );
  }
}
