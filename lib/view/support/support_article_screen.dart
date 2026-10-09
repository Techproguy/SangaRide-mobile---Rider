import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_help_controller.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/widgets/article_body.dart';
import 'package:sanga_ride/view/support/widgets/article_feedback.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SupportArticleScreen extends StatefulWidget {
  const SupportArticleScreen({super.key, required this.id});

  final String id;

  @override
  State<SupportArticleScreen> createState() => _SupportArticleScreenState();
}

class _SupportArticleScreenState extends State<SupportArticleScreen> {
  final _controller = Get.find<SupportHelpController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.loadArticle(widget.id));
    });
  }

  Widget _loaded(ArticleLoaded state) {
    final article = state.article;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        Text(article.title, style: SangaTextStyles.headline),
        ArticleBody(blocks: article.blocks),
        const SizedBox(height: SangaSpacing.xs),
        ArticleFeedback(
          vote: state.vote,
          isVoting: state.isVoting,
          onVote: (isHelpful) => _controller.vote(widget.id, isHelpful: isHelpful),
          onContact: () => context.push(SupportRoutes.contact),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.detailFor(widget.id);
      return SangaPageLayout(
        title: 'Help article',
        children: [
          switch (state) {
            ArticleLoading() => const SangaSkeleton.heights([32, 120, 56]),
            ArticleFailed(:final problem) => SangaFailureMessage(
              message: problem.message,
              onRetry: () => _controller.loadArticle(widget.id),
            ),
            final ArticleLoaded loaded => _loaded(loaded),
          },
        ],
      );
    });
  }
}
