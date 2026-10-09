import 'package:sanga_ride/model/support/support_home.dart';
import 'package:sanga_ride/model/support/support_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

sealed class ArticleBlock {
  const ArticleBlock();

  factory ArticleBlock.fromReader(JsonReader reader) => switch (reader.strOrNull('type')) {
    'bullets' => BulletsBlock(reader.strings('items')),
    _ => ParagraphBlock(reader.str('text')),
  };
}

final class ParagraphBlock extends ArticleBlock {
  const ParagraphBlock(this.text);

  final String text;
}

final class BulletsBlock extends ArticleBlock {
  const BulletsBlock(this.items);

  final List<String> items;
}

class SupportArticle {
  const SupportArticle({
    required this.id,
    required this.title,
    required this.blocks,
    required this.helpfulCount,
    required this.notHelpfulCount,
  });

  factory SupportArticle.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return SupportArticle(
      id: reader.str('id'),
      title: reader.str('title'),
      blocks: reader.listOf('body', ArticleBlock.fromReader),
      helpfulCount: reader.intOr('helpfulCount', 0),
      notHelpfulCount: reader.intOr('notHelpfulCount', 0),
    );
  }

  final String id;
  final String title;
  final List<ArticleBlock> blocks;
  final int helpfulCount;
  final int notHelpfulCount;
}

enum ArticleVote { none, helpful, notHelpful }

sealed class ArticleState {
  const ArticleState();
}

final class ArticleLoading extends ArticleState {
  const ArticleLoading();
}

final class ArticleFailed extends ArticleState {
  const ArticleFailed(this.problem);

  final SupportProblem problem;
}

final class ArticleLoaded extends ArticleState {
  const ArticleLoaded(this.article, {this.vote = ArticleVote.none, this.isVoting = false});

  final SupportArticle article;
  final ArticleVote vote;
  final bool isVoting;
}

typedef ArticleQuery = ({String? topic, String text});

class ArticlePage {
  const ArticlePage({required this.items, required this.page, required this.hasMore});

  factory ArticlePage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ArticlePage(
      items: reader.listOf('items', ArticleSummary.fromReader),
      page: reader.intOr('page', 1),
      hasMore: reader.boolOr('hasMore', false),
    );
  }

  final List<ArticleSummary> items;
  final int page;
  final bool hasMore;
}

sealed class ArticlesState {
  const ArticlesState();
}

final class ArticlesLoading extends ArticlesState {
  const ArticlesLoading();
}

final class ArticlesFailed extends ArticlesState {
  const ArticlesFailed(this.problem);

  final SupportProblem problem;
}

final class ArticlesLoaded extends ArticlesState {
  const ArticlesLoaded(
    this.items, {
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<ArticleSummary> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  ArticlesLoaded copyWith({bool? isLoadingMore, bool? loadMoreFailed}) => ArticlesLoaded(
    items,
    page: page,
    hasMore: hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

extension TopicLookup on SupportHomeState {
  SupportTopic? topicById(String id) => switch (this) {
    SupportHomeLoaded(:final home) => home.topicById(id),
    _ => null,
  };
}
