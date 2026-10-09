import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/support_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class SupportHelpController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<SupportHomeState> _home = Rx<SupportHomeState>(const SupportHomeLoading());
  final RxMap<ArticleQuery, ArticlesState> _articles = <ArticleQuery, ArticlesState>{}.obs;
  final RxMap<String, ArticleState> _details = <String, ArticleState>{}.obs;

  SupportHomeState get home => _home.value;

  ArticlesState articlesFor(ArticleQuery query) => _articles[query] ?? const ArticlesLoading();

  ArticleState detailFor(String id) => _details[id] ?? const ArticleLoading();

  Future<void> loadHome() async {
    if (_home.value is! SupportHomeLoaded) _home.value = const SupportHomeLoading();
    try {
      final response = await _api.get(SupportEndpoints.home, options: quietOptions);
      _home.value = SupportHomeLoaded(SupportHome.fromJson(dataOf(response)));
    } on Object catch (error) {
      if (_home.value is! SupportHomeLoaded) _home.value = SupportHomeFailed(SupportProblem.of(error));
    }
  }

  Future<void> loadArticles(ArticleQuery query) async {
    _articles[query] = const ArticlesLoading();
    try {
      final page = await _fetchArticles(query, 1);
      _articles[query] = ArticlesLoaded(page.items, page: page.page, hasMore: page.hasMore);
    } on Object catch (error) {
      _articles[query] = ArticlesFailed(SupportProblem.of(error));
    }
  }

  Future<void> loadMoreArticles(ArticleQuery query) async {
    final current = _articles[query];
    if (current is! ArticlesLoaded || !current.hasMore || current.isLoadingMore) return;
    _articles[query] = current.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await _fetchArticles(query, current.page + 1);
      _articles[query] = ArticlesLoaded([...current.items, ...page.items], page: page.page, hasMore: page.hasMore);
    } on Object {
      _articles[query] = current.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  Future<void> loadArticle(String id) async {
    if (_details[id] is! ArticleLoaded) _details[id] = const ArticleLoading();
    try {
      final response = await _api.get(SupportEndpoints.of(SupportEndpoints.article, id), options: quietOptions);
      final current = _details[id];
      _details[id] = ArticleLoaded(
        SupportArticle.fromJson(dataOf(response)),
        vote: current is ArticleLoaded ? current.vote : ArticleVote.none,
      );
    } on Object catch (error) {
      if (_details[id] is! ArticleLoaded) _details[id] = ArticleFailed(SupportProblem.of(error));
    }
  }

  Future<void> vote(String id, {required bool isHelpful}) async {
    final current = _details[id];
    if (current is! ArticleLoaded || current.isVoting || current.vote != ArticleVote.none) return;
    final vote = isHelpful ? ArticleVote.helpful : ArticleVote.notHelpful;
    _details[id] = ArticleLoaded(current.article, vote: vote, isVoting: true);
    try {
      final response = await _api.post(
        SupportEndpoints.of(SupportEndpoints.articleFeedback, id),
        data: {'helpful': isHelpful},
        options: quietOptions,
      );
      _details[id] = ArticleLoaded(SupportArticle.fromJson(dataOf(response)), vote: vote);
    } on Object {
      _details[id] = ArticleLoaded(current.article, vote: vote);
    }
  }

  Future<ArticlePage> _fetchArticles(ArticleQuery query, int page) async {
    final response = await _api.get(
      SupportEndpoints.articles,
      queryParameters: {'topic': ?query.topic, if (query.text.isNotEmpty) 'q': query.text, 'page': page},
      options: quietOptions,
    );
    return ArticlePage.fromJson(dataOf(response));
  }
}
