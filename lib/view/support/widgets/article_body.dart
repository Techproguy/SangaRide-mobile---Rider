import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ArticleBody extends StatelessWidget {
  const ArticleBody({super.key, required this.blocks});

  final List<ArticleBlock> blocks;

  Widget _block(ArticleBlock block) => switch (block) {
    ParagraphBlock(:final text) => Text(text, style: SangaTextStyles.body.copyWith(color: SangaColors.textPrimary)),
    BulletsBlock(:final items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        for (final item in items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.sm,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: SangaSpacing.xs),
                child: Icon(Icons.circle, size: 6, color: SangaColors.primary),
              ),
              Expanded(
                child: Text(item, style: SangaTextStyles.body.copyWith(color: SangaColors.textPrimary)),
              ),
            ],
          ),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [for (final block in blocks) _block(block)],
    );
  }
}
