import 'dart:developer';

import 'package:dio/dio.dart' show Options;
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/history_endpoints.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/model/history/history_item.dart';

class RideHistoryController extends GetxController {
  static const int pageSize = 10;
  static final Options _quiet = Options(extra: {'suppressErrorToast': true});

  final _api = Get.find<ApiService>();

  final RxMap<HistoryStatus, HistoryFeedState> _feeds = <HistoryStatus, HistoryFeedState>{}.obs;
  final Map<HistoryStatus, int> _feedEpochs = {};
  final Rx<HistoryDetailState> _detail = Rx<HistoryDetailState>(const HistoryDetailLoading());
  String? _detailId;
  int _detailEpoch = 0;

  HistoryFeedState feed(HistoryStatus status) => _feeds[status] ?? const HistoryFeedLoading();

  HistoryDetailState get detailState => _detail.value;

  HistoryDetailState detailStateFor(String id) => _detailId == id ? detailState : const HistoryDetailLoading();

  Future<void> open(HistoryStatus status) async {
    if (_feeds[status] is HistoryFeedLoaded) return;
    await _loadFirstPage(status);
  }

  Future<void> reload(HistoryStatus status) => _loadFirstPage(status);

  Future<void> _loadFirstPage(HistoryStatus status) async {
    final epoch = _nextEpoch(status);
    final current = _feeds[status];
    if (current is! HistoryFeedLoaded) _feeds[status] = const HistoryFeedLoading();
    try {
      final page = await _fetch(status, 1);
      if (epoch != _feedEpochs[status]) return;
      _feeds[status] = HistoryFeedLoaded(items: page.items, page: page.page, hasMore: page.hasMore);
    } catch (e) {
      log('load ${status.code} history failed: $e');
      if (epoch == _feedEpochs[status] && _feeds[status] is! HistoryFeedLoaded) {
        _feeds[status] = const HistoryFeedFailed();
      }
    }
  }

  Future<void> loadMore(HistoryStatus status) async {
    final current = _feeds[status];
    if (current is! HistoryFeedLoaded || !current.hasMore || current.more == HistoryMore.loading) return;
    final epoch = _nextEpoch(status);
    _feeds[status] = current.copyWith(more: HistoryMore.loading);
    try {
      final page = await _fetch(status, current.page + 1);
      if (epoch != _feedEpochs[status]) return;
      _feeds[status] = HistoryFeedLoaded(
        items: [...current.items, ...page.items],
        page: page.page,
        hasMore: page.hasMore,
      );
    } catch (e) {
      log('load more ${status.code} history failed: $e');
      if (epoch == _feedEpochs[status]) _feeds[status] = current.copyWith(more: HistoryMore.failed);
    }
  }

  int _nextEpoch(HistoryStatus status) => _feedEpochs[status] = (_feedEpochs[status] ?? 0) + 1;

  Future<HistoryPage> _fetch(HistoryStatus status, int page) async {
    final response = await _api.get(
      HistoryEndpoints.rides,
      queryParameters: {'status': status.code, 'page': page, 'pageSize': pageSize},
      suppressErrorToast: true,
    );
    return HistoryPage.fromJson(Map<String, dynamic>.from((response.data as Map)['data'] as Map));
  }

  Future<void> openDetail(String id) async {
    if (_detailId == id && detailState is HistoryDetailLoaded) return;
    _detailId = id;
    await _loadDetail();
  }

  Future<void> reloadDetail() async {
    if (_detailId == null || detailState is HistoryDetailLoading) return;
    await _loadDetail();
  }

  Future<void> _loadDetail() async {
    final id = _detailId;
    if (id == null) return;
    final epoch = ++_detailEpoch;
    _detail.value = const HistoryDetailLoading();
    try {
      final response = await _api.get(HistoryEndpoints.rideOf(id), suppressErrorToast: true);
      if (epoch != _detailEpoch) return;
      final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
      _detail.value = HistoryDetailLoaded(HistoryDetail.fromJson(data));
    } catch (e) {
      log('load history detail failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch == _detailEpoch) {
        _detail.value = HistoryDetailFailed(HistoryFailure.fromCode(e is ApiException ? e.code : null));
      }
    }
  }

  Future<HistoryProblem?> setDriverBlocked(bool isBlocked) async {
    final current = detailState;
    if (current is! HistoryDetailLoaded || current.driverAction != null) return null;
    final driver = current.detail.driver;
    if (driver == null) return HistoryProblem.driverNotFound;
    final epoch = _detailEpoch;
    _detail.value = HistoryDetailLoaded(
      current.detail,
      driverAction: isBlocked ? HistoryDriverAction.blocking : HistoryDriverAction.unblocking,
    );
    try {
      final endpoint = HistoryEndpoints.blockDriverOf(driver.profile.id);
      if (isBlocked) {
        await _api.post(endpoint, suppressErrorToast: true);
      } else {
        await _api.delete(endpoint, options: _quiet);
      }
      if (epoch == _detailEpoch) {
        _detail.value = HistoryDetailLoaded(current.detail.withDriver(driver.copyWith(isBlocked: isBlocked)));
      }
      return null;
    } catch (e) {
      log('set driver blocked failed: ${e is ApiException ? e.code : e.runtimeType}');
      if (epoch == _detailEpoch) _detail.value = HistoryDetailLoaded(current.detail);
      return HistoryProblem.fromCode(e is ApiException ? e.code : null);
    }
  }
}
