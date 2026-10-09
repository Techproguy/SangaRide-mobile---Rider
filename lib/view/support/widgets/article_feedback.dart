import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/support_copy.dart';
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
                Text(SupportCopy.wasHelpful, textAlign: TextAlign.center, style: SangaTextStyles.cardTitle),
                Row(
                  spacing: SangaSpacing.sm,
                  children: [
                    Expanded(
                      child: SangaButton.outline(
                        label: SupportCopy.yes,
                        size: SangaButtonSize.compact,
                        onPressed: isVoting ? null : () => onVote(true),
                      ),
                    ),
                    Expanded(
                      child: SangaButton.outline(
                        label: SupportCopy.no,
                        size: SangaButtonSize.compact,
                        onPressed: isVoting ? null : () => onVote(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ArticleVote.helpful => Text(
              SupportCopy.gladHelped,
              textAlign: TextAlign.center,
              style: SangaTextStyles.cardTitle,
            ),
            ArticleVote.notHelpful => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.sm,
              children: [
                Text(SupportCopy.sorryAboutThat, textAlign: TextAlign.center, style: SangaTextStyles.cardTitle),
                SangaButton.primary(
                  label: SupportCopy.contactSupport,
                  size: SangaButtonSize.compact,
                  onPressed: onContact,
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}
