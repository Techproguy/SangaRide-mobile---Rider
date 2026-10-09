import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/wallet_endpoints.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';

class WalletController extends GetxController {
  WalletController(this.scope);

  static const int recentCount = 5;

  final WalletScope scope;
  final _api = Get.find<ApiService>();

  final Rx<WalletState> _state = Rx<WalletState>(const WalletLoading());
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

  Future<void> _load() async {
    final epoch = ++_epoch;
    final previous = state;
    final results = await Future.wait([_fetchOverview(), _fetchRecent()]);
    if (epoch != _epoch) return;
    final overview = results[0] as WalletOverview?;
    final recent = results[1] as RecentTransactions;
    if (overview != null) {
      _state.value = WalletLoaded(overview, recent);
    } else if (previous is! WalletLoaded) {
      _state.value = const WalletFailed();
    }
  }

  Future<WalletOverview?> _fetchOverview() async {
    try {
      final response = await _api.get(WalletEndpoints.walletOf(scope.groupId), suppressErrorToast: true);
      return WalletOverview.fromJson(_dataOf(response.data));
    } catch (e) {
      log('wallet load failed: ${e is ApiException ? e.code : e.runtimeType}');
      return null;
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
    } catch (e) {
      log('recent transactions failed: ${e is ApiException ? e.code : e.runtimeType}');
      return const RecentFailed();
    }
  }

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
