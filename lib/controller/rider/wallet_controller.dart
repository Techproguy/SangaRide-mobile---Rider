import 'dart:async';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/wallet_endpoints.dart';
import 'package:sanga_ride/model/account/load_problem.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class WalletController extends GetxController {
  WalletController(this.scope);

  static const int recentCount = 5;
  static const Duration transferWatchInterval = Duration(seconds: 5);

  final WalletScope scope;
  final _api = Get.find<ApiService>();

  final Rx<WalletState> _state = Rx<WalletState>(const WalletLoading());
  LivePoller? _watcher;
  int _epoch = 0;

  Rx<WalletState> get stateRx => _state;

  WalletState get state => _state.value;

  WalletOverview? get overview => switch (state) {
    WalletLoaded(:final overview) => overview,
    _ => null,
  };

  int? get balance => overview?.balance;

  @override
  void onClose() {
    _epoch++;
    _stopWatching();
    super.onClose();
  }

  Future<void> open() async {
    if (state is WalletLoaded) return reloadQuietly();
    await reload();
  }

  Future<void> reload() async {
    _state.value = const WalletLoading();
    await _load();
  }

  Future<void> reloadQuietly() => _load();

  Future<bool> reloadFresh() async {
    await _load();
    final current = state;
    return current is WalletLoaded && !current.isStale;
  }

  Future<void> _load() async {
    final epoch = ++_epoch;
    final previous = state;
    final overviewResult = _fetchOverview();
    final recentResult = _fetchRecent();
    final fetched = await overviewResult;
    final recent = await recentResult;
    if (epoch != _epoch) return;
    final overview = fetched.overview;
    if (overview != null) {
      _state.value = WalletLoaded(overview, recent);
    } else if (previous is WalletLoaded) {
      _state.value = previous.markStale();
    } else {
      _state.value = WalletFailed(fetched.problem ?? LoadProblem.unknown);
    }
    _syncWatcher();
  }

  Future<({WalletOverview? overview, LoadProblem? problem})> _fetchOverview() async {
    try {
      final response = await _api.get(WalletEndpoints.walletOf(scope.groupId), suppressErrorToast: true);
      return (overview: WalletOverview.fromJson(_dataOf(response.data)), problem: null);
    } on Object catch (error) {
      return (overview: null, problem: LoadProblem.of(error));
    }
  }

  Future<RecentTransactions> _fetchRecent() async {
    try {
      final response = await _api.get(
        WalletEndpoints.transactionsOf(scope.groupId),
        queryParameters: {'page': 1, 'limit': recentCount},
        suppressErrorToast: true,
      );
      return RecentLoaded(TransactionPage.fromJson(_dataOf(response.data)).entries);
    } on Object catch (error) {
      return RecentFailed(LoadProblem.of(error));
    }
  }

  void _syncWatcher() {
    final current = state;
    final hasPending =
        current is WalletLoaded &&
        switch (current.recent) {
          RecentLoaded(:final pendingTransfer) => pendingTransfer != null,
          _ => false,
        };
    if (!hasPending) return _stopWatching();
    if (_watcher != null) return;
    final watcher = LivePoller(fetch: _watchOnce, interval: transferWatchInterval);
    _watcher = watcher;
    watcher.start();
  }

  Future<void> _watchOnce() async {
    final epoch = ++_epoch;
    final overview = await _fetchOverviewOrThrow();
    final recent = await _fetchRecentOrThrow();
    if (epoch != _epoch) return;
    _state.value = WalletLoaded(overview, recent);
    _syncWatcher();
  }

  Future<WalletOverview> _fetchOverviewOrThrow() async {
    final response = await _api.get(WalletEndpoints.walletOf(scope.groupId), suppressErrorToast: true);
    return WalletOverview.fromJson(_dataOf(response.data));
  }

  Future<RecentTransactions> _fetchRecentOrThrow() async {
    final response = await _api.get(
      WalletEndpoints.transactionsOf(scope.groupId),
      queryParameters: {'page': 1, 'limit': recentCount},
      suppressErrorToast: true,
    );
    return RecentLoaded(TransactionPage.fromJson(_dataOf(response.data)).entries);
  }

  void _stopWatching() {
    final watcher = _watcher;
    _watcher = null;
    if (watcher != null) Future<void>.microtask(watcher.dispose);
  }

  Map<String, dynamic> _dataOf(dynamic body) => JsonReader.of(JsonReader.of(body).raw['data']).raw;
}
