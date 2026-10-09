import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_help_controller.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/widgets/article_row.dart';
import 'package:sanga_ride/view/support/widgets/support_topic_grid.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({super.key});

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  final _controller = Get.find<SupportHelpController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.loadHome());
    });
  }

  Widget _contactGroup() {
    return SangaListGroup(
      children: [
        SangaListRow(
          leading: const SangaIconBadge(size: 36, child: Icon(Icons.headset_mic_outlined)),
          title: 'Contact support',
          subtitle: 'Chat, call or report an issue',
          onTap: () => context.push(SupportRoutes.contact),
        ),
        SangaListRow(
          leading: const SangaIconBadge(size: 36, child: Icon(Icons.assignment_outlined)),
          title: 'My reports',
          subtitle: 'Follow up on issues you reported',
          onTap: () => context.push(SupportRoutes.tickets),
        ),
      ],
    );
  }

  Widget _loaded(SupportHome home) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        SangaSearchTrigger(
          hint: 'Search for help articles',
          onTap: () => context.push(SupportRoutes.articlesOf(focusSearch: true)),
        ),
        if (home.topics.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.sm,
            children: [
              const SangaSectionHeader('Common topics'),
              SupportTopicGrid(
                topics: home.topics,
                onSelected: (topic) => context.push(SupportRoutes.articlesOf(topic: topic.id)),
              ),
            ],
          ),
        if (home.popular.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.sm,
            children: [
              const SangaSectionHeader('Popular articles'),
              SangaListGroup(
                children: [
                  for (final article in home.popular)
                    ArticleRow(article: article, onTap: () => context.push(SupportRoutes.articleOf(article.id))),
                ],
              ),
            ],
          ),
        _contactGroup(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.home;
      return SangaPageLayout(
        title: 'Support',
        children: [
          switch (state) {
            SupportHomeLoading() => const SangaSkeleton.heights([48, 120, 56, 56]),
            SupportHomeFailed(:final problem) => SangaFailureMessage(
              message: problem.message,
              onRetry: _controller.loadHome,
            ),
            SupportHomeLoaded(:final home) => _loaded(home),
          },
        ],
      );
    });
  }
}
