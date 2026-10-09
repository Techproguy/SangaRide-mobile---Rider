import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_help_controller.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/widgets/article_row.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SupportArticlesScreen extends StatefulWidget {
  const SupportArticlesScreen({super.key, this.topic, this.focusSearch = false});

  final String? topic;
  final bool focusSearch;

  @override
  State<SupportArticlesScreen> createState() => _SupportArticlesScreenState();
}

class _SupportArticlesScreenState extends State<SupportArticlesScreen> {
  static const Duration _debounce = Duration(milliseconds: 350);
  static const double _loadMoreExtent = 320;

  final _controller = Get.find<SupportHelpController>();
  final _search = TextEditingController();
  Timer? _timer;
  String _text = '';

  ArticleQuery get _query => (topic: widget.topic, text: _text);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.loadHome());
      unawaited(_controller.loadArticles(_query));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < _loadMoreExtent) unawaited(_controller.loadMoreArticles(_query));
    return false;
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => _apply(value.trim()));
  }

  void _apply(String text) {
    if (!mounted || text == _text) return;
    setState(() => _text = text);
    unawaited(_controller.loadArticles(_query));
  }

  String get _title {
    final id = widget.topic;
    if (id == null) return 'Help articles';
    return _controller.home.topicById(id)?.label ?? 'Help articles';
  }

  Widget _list(ArticlesLoaded state) {
    if (state.items.isEmpty) return _empty();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SangaListGroup(
          children: [
            for (final article in state.items)
              ArticleRow(article: article, onTap: () => context.push(SupportRoutes.articleOf(article.id))),
          ],
        ),
        if (state.isLoadingMore) const SangaSkeleton.heights([56]),
        if (state.loadMoreFailed)
          SangaFailureMessage(
            message: SupportProblem.connection.message,
            title: 'We couldn’t load more',
            onRetry: () => _controller.loadMoreArticles(_query),
          ),
      ],
    );
  }

  Widget _empty() {
    final hasText = _text.isNotEmpty;
    return SangaEmptyMessage(
      icon: Icons.search_off_rounded,
      title: hasText ? 'Nothing found for “$_text”' : 'No articles here yet',
      message: hasText ? 'Try different words, or talk to our team.' : 'Check back soon, or talk to our team.',
      actionLabel: 'Contact support',
      onAction: () => context.push(SupportRoutes.contact),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.articlesFor(_query);
      return NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: SangaPageLayout(
          title: _title,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.md,
              children: [
                SangaSearchField(
                  controller: _search,
                  hintText: 'Search for help articles',
                  autofocus: widget.focusSearch,
                  onChanged: _onChanged,
                  onCleared: () => _apply(''),
                ),
                switch (state) {
                  ArticlesLoading() => const SangaSkeleton.heights([56, 56, 56]),
                  ArticlesFailed(:final problem) => SangaFailureMessage(
                    message: problem.message,
                    onRetry: () => _controller.loadArticles(_query),
                  ),
                  final ArticlesLoaded loaded => _list(loaded),
                },
              ],
            ),
          ],
        ),
      );
    });
  }
}
