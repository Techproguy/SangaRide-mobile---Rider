import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/wallet_endpoints.dart';
import 'package:sanga_ride/model/account/load_problem.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class WalletTransactionsController extends GetxController {
  WalletTransactionsController(this.scope);

  static const int pageSize = 20;

  final WalletScope scope;
  final _api = Get.find<ApiService>();

  final Rx<TransactionFilter> _filter = TransactionFilter.all.obs;
  final RxMap<TransactionFilter, TransactionFeed> _feeds = <TransactionFilter, TransactionFeed>{}.obs;
  final Map<TransactionFilter, int> _feedEpochs = {};
  final Rx<TransactionDetailState> _detail = Rx<TransactionDetailState>(const TransactionDetailLoading());
  String? _detailId;
  int _detailEpoch = 0;

  TransactionFilter get filter => _filter.value;

  TransactionFeed get feed => _feeds[filter] ?? const TransactionsLoading();

  TransactionDetailState detailFor(String id) {
    final detail = _detail.value;
    return _detailId == id ? detail : const TransactionDetailLoading();
  }

  Future<void> open() => select(TransactionFilter.all);

  Future<void> select(TransactionFilter next) async {
    _filter.value = next;
    await _loadFirstPage(next);
  }

  Future<void> retry() async {
    final current = filter;
    _feeds[current] = const TransactionsLoading();
    await _loadFirstPage(current);
  }

  Future<void> refreshFeed() => _loadFirstPage(filter);

  int _nextEpoch(TransactionFilter target) => _feedEpochs[target] = (_feedEpochs[target] ?? 0) + 1;

  Future<void> _loadFirstPage(TransactionFilter target) async {
    final epoch = _nextEpoch(target);
    if (_feeds[target] is! TransactionsLoaded) _feeds[target] = const TransactionsLoading();
    try {
      final page = await _fetch(target, 1);
      if (epoch != _feedEpochs[target]) return;
      _feeds[target] = TransactionsLoaded(page.entries, page: page.page, hasMore: page.hasMore);
    } on Object catch (error) {
      if (epoch != _feedEpochs[target]) return;
      final current = _feeds[target];
      _feeds[target] = current is TransactionsLoaded ? current.markStale() : TransactionsFailed(LoadProblem.of(error));
    }
  }

  Future<void> loadMore() async {
    final target = filter;
    final current = _feeds[target];
    if (current is! TransactionsLoaded || !current.hasMore || current.more == TransactionMore.loading) return;
    final epoch = _nextEpoch(target);
    _feeds[target] = current.withMore(TransactionMore.loading);
    try {
      final next = await _fetch(target, current.page + 1);
      if (epoch != _feedEpochs[target]) return;
      _feeds[target] = TransactionsLoaded(
        [...current.entries, ...next.entries],
        page: next.page,
        hasMore: next.hasMore,
      );
    } on Object {
      if (epoch == _feedEpochs[target]) _feeds[target] = current.withMore(TransactionMore.failed);
    }
  }

  Future<void> openDetail(String id) async {
    _detailId = id;
    _detail.value = const TransactionDetailLoading();
    await _loadDetail();
  }

  Future<void> reloadDetail() async {
    _detail.value = const TransactionDetailLoading();
    await _loadDetail();
  }

  Future<void> refreshDetail() => _loadDetail();

  Future<void> _loadDetail() async {
    final id = _detailId;
    if (id == null) return;
    final epoch = ++_detailEpoch;
    try {
      final response = await _api.get(
        WalletEndpoints.transactionAt(id, groupId: scope.groupId),
        suppressErrorToast: true,
      );
      if (epoch != _detailEpoch) return;
      _detail.value = TransactionDetailLoaded(WalletTransaction.fromJson(_dataOf(response.data)));
    } on Object catch (error) {
      if (epoch != _detailEpoch) return;
      final failure = TransactionFailure.of(error);
      if (_detail.value is TransactionDetailLoaded && failure.canRetry) return;
      _detail.value = TransactionDetailFailed(failure);
    }
  }

  Future<TransactionPage> _fetch(TransactionFilter target, int page) async {
    final response = await _api.get(
      WalletEndpoints.transactionsOf(scope.groupId),
      queryParameters: {'page': page, 'limit': pageSize, 'kind': ?target.query},
      suppressErrorToast: true,
    );
    return TransactionPage.fromJson(_dataOf(response.data));
  }

  Map<String, dynamic> _dataOf(dynamic body) => JsonReader.of(JsonReader.of(body).raw['data']).raw;
}
