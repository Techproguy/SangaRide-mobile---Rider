import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ArticleRow extends StatelessWidget {
  const ArticleRow({super.key, required this.article, required this.onTap});

  final ArticleSummary article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SangaListRow(
      leading: const SangaIconBadge(size: 36, child: Icon(Icons.article_outlined)),
      title: article.title,
      subtitle: article.summary.isEmpty ? null : article.summary,
      titleMaxLines: 2,
      onTap: onTap,
    );
  }
}
