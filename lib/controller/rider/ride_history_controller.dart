import 'package:get/get.dart';
import 'package:sanga_ride/model/account/load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/app_endpoints.dart';
import 'package:sanga_ride/core/api/group_endpoints.dart';
import 'package:sanga_ride/core/api/history_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/model/history/history_scope.dart';

class RideHistoryController extends GetxController {
  RideHistoryController([this.scope = const HistoryScope.personal()]);

  static const int pageSize = 10;

  final HistoryScope scope;
  final _api = Get.find<ApiService>();

  final RxMap<HistoryStatus, HistoryFeedState> _feeds = <HistoryStatus, HistoryFeedState>{}.obs;
  final RxnString _memberId = RxnString();
  final Map<HistoryStatus, Epoch> _feedEpochs = {};
  final Rx<HistoryDetailState> _detail = Rx<HistoryDetailState>(const HistoryDetailLoading());
  final RxnString _detailId = RxnString();
  final _detailEpoch = Epoch();

  String? get memberId => _memberId.value;

  HistoryFeedState feed(HistoryStatus status) => _feeds[status] ?? const HistoryFeedLoading();

  HistoryDetailState get detailState => _detail.value;

  HistoryDetailState detailStateFor(String id) => _detailId.value == id ? detailState : const HistoryDetailLoading();

  Future<void> open(HistoryStatus status) => _loadFirstPage(status);

  Future<void> reload(HistoryStatus status) => _loadFirstPage(status);

  Future<void> selectMember(String? id) async {
    if (id == _memberId.value) return;
    _memberId.value = id;
    final opened = _feeds.keys.toList();
    _feeds.clear();
    await Future.wait([for (final status in opened) _loadFirstPage(status)]);
  }

  Future<void> _loadFirstPage(HistoryStatus status) async {
    final epoch = _nextEpoch(status);
    final current = _feeds[status];
    if (current is! HistoryFeedLoaded) _feeds[status] = const HistoryFeedLoading();
    try {
      final page = await _fetch(status, 1);
      if (!_isCurrentFeed(status, epoch)) return;
      _feeds[status] = HistoryFeedLoaded(items: page.items, page: page.page, hasMore: page.hasMore);
    } on Object catch (error) {
      if (!_isCurrentFeed(status, epoch)) return;
      final latest = _feeds[status];
      _feeds[status] = latest is HistoryFeedLoaded
          ? latest.copyWith(isStale: true)
          : HistoryFeedFailed(LoadProblem.of(error));
    }
  }

  Future<void> loadMore(HistoryStatus status) async {
    final current = _feeds[status];
    if (current is! HistoryFeedLoaded || !current.hasMore || current.more == HistoryMore.loading) return;
    final epoch = _nextEpoch(status);
    _feeds[status] = current.copyWith(more: HistoryMore.loading);
    try {
      final page = await _fetch(status, current.page + 1);
      if (!_isCurrentFeed(status, epoch)) return;
      _feeds[status] = HistoryFeedLoaded(
        items: [...current.items, ...page.items],
        page: page.page,
        hasMore: page.hasMore,
      );
    } on Object {
      if (_isCurrentFeed(status, epoch)) _feeds[status] = current.copyWith(more: HistoryMore.failed);
    }
  }

  int _nextEpoch(HistoryStatus status) => (_feedEpochs[status] ??= Epoch()).next();

  bool _isCurrentFeed(HistoryStatus status, int epoch) => _feedEpochs[status]?.isCurrent(epoch) ?? false;

  Future<HistoryPage> _fetch(HistoryStatus status, int page) async {
    final groupId = scope.groupId;
    if (groupId != null) {
      final response = await _api.get(
        GroupEndpoints.ridesOf(groupId),
        queryParameters: {'status': status.code, 'page': page, 'pageSize': pageSize, 'memberId': ?memberId},
        suppressErrorToast: true,
      );
      return HistoryPage.fromJson(response.dataMapOrEmpty);
    }
    final response = await _api.get(
      HistoryEndpoints.rides,
      queryParameters: {'status': status.code, 'page': page, 'limit': pageSize},
      suppressErrorToast: true,
    );
    return HistoryPage.fromRides(response.dataMapOrEmpty, page: page, limit: pageSize);
  }

  Future<void> openDetail(String id) async {
    final isSame = _detailId.value == id;
    _detailId.value = id;
    await _loadDetail(showLoading: !isSame || detailState is! HistoryDetailLoaded);
  }

  Future<void> reloadDetail() async {
    if (_detailId.value == null || detailState is HistoryDetailLoading) return;
    await _loadDetail(showLoading: detailState is! HistoryDetailLoaded);
  }

  Future<void> refreshDetail() async {
    if (_detailId.value == null) return;
    await _loadDetail(showLoading: false);
  }

  Future<void> _loadDetail({required bool showLoading}) async {
    final id = _detailId.value;
    if (id == null) return;
    final epoch = _detailEpoch.next();
    final previous = detailState;
    if (showLoading) _detail.value = const HistoryDetailLoading();
    try {
      final response = await _api.get(HistoryEndpoints.rideOf(id), suppressErrorToast: true);
      final ride = response.dataMapOrEmpty;
      final (receipt, blockedDriverIds) = await (
        ride['status'] == HistoryStatus.completed.code ? _fetchReceipt(id) : Future<Map<String, dynamic>?>.value(),
        _fetchBlockedDriverIds(),
      ).wait;
      if (!_detailEpoch.isCurrent(epoch)) return;
      final latest = detailState;
      _detail.value = HistoryDetailLoaded(
        HistoryDetail.fromRide(ride, receipt: receipt, blockedDriverIds: blockedDriverIds ?? _blockedIdsOf(previous)),
        driverAction: latest is HistoryDetailLoaded ? latest.driverAction : null,
      );
    } on Object catch (error) {
      if (!_detailEpoch.isCurrent(epoch)) return;
      final failure = HistoryFailure.of(error);
      final keepsPrevious = previous is HistoryDetailLoaded && failure.canRetry;
      _detail.value = keepsPrevious
          ? HistoryDetailLoaded(previous.detail, driverAction: previous.driverAction, isStale: true)
          : HistoryDetailFailed(failure);
    }
  }

  Future<Map<String, dynamic>?> _fetchReceipt(String id) async {
    try {
      final response = await _api.get(AppEndpoints.tripReceiptOf(id), suppressErrorToast: true);
      return response.dataMapOrEmpty;
    } on Object {
      return null;
    }
  }

  Future<Set<String>?> _fetchBlockedDriverIds() async {
    try {
      final response = await _api.get(HistoryEndpoints.blockedDrivers, suppressErrorToast: true);
      final body = response.data;
      final entries = body is Map ? body['data'] : null;
      return {
        if (entries is List)
          for (final entry in entries.whereType<Map>())
            if ('${entry['driverId'] ?? entry['id'] ?? ''}' case final driverId when driverId.isNotEmpty) driverId,
      };
    } on Object {
      return null;
    }
  }

  Set<String> _blockedIdsOf(HistoryDetailState state) {
    if (state is! HistoryDetailLoaded) return const {};
    final driver = state.detail.driver;
    return {if (driver != null && driver.isBlocked) driver.profile.id};
  }

  Future<HistoryProblem?> setDriverBlocked(bool isBlocked) async {
    final current = detailState;
    if (current is! HistoryDetailLoaded || current.driverAction != null) return null;
    final driver = current.detail.driver;
    if (driver == null) return HistoryProblem.driverNotFound;
    final epoch = _detailEpoch.current;
    _detail.value = HistoryDetailLoaded(
      current.detail,
      driverAction: isBlocked ? HistoryDriverAction.blocking : HistoryDriverAction.unblocking,
    );
    try {
      if (isBlocked) {
        await _api.post(
          HistoryEndpoints.blockedDrivers,
          data: {'driverId': driver.profile.id},
          key: IdempotencyKey.newFor(IdempotencyIntent.blockDriver),
          suppressErrorToast: true,
        );
      } else {
        await _api.delete(
          HistoryEndpoints.blockedDriverOf(driver.profile.id),
          key: IdempotencyKey.newFor(IdempotencyIntent.unblockDriver),
          suppressErrorToast: true,
        );
      }
      if (_detailEpoch.isCurrent(epoch)) {
        _detail.value = HistoryDetailLoaded(current.detail.withDriver(driver.copyWith(isBlocked: isBlocked)));
      }
      return null;
    } on Object catch (error) {
      if (_detailEpoch.isCurrent(epoch)) _detail.value = HistoryDetailLoaded(current.detail);
      return HistoryProblem.of(error);
    }
  }
}
