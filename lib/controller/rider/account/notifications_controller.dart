import 'dart:async';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/notification_endpoints.dart';
import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class NotificationsController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<NotificationsState> _state = Rx<NotificationsState>(const NotificationsLoading());
  final RxInt _unreadCount = 0.obs;

  StreamSubscription<void>? _resumeSubscription;
  int _epoch = 0;

  NotificationsState get state => _state.value;

  int get unreadCount => _unreadCount.value;

  @override
  void onInit() {
    super.onInit();
    _resumeSubscription = AppLifecycle.instance.onResume.listen((_) {
      if (SessionStorage.tokens.hasSession && _state.value is NotificationsLoaded) unawaited(reload());
    });
  }

  @override
  void onClose() {
    _resumeSubscription?.cancel();
    _epoch++;
    super.onClose();
  }

  Future<void> reload() async {
    final epoch = ++_epoch;
    try {
      final page = await _fetch(1);
      if (epoch != _epoch) return;
      _unreadCount.value = page.unreadCount;
      _state.value = NotificationsLoaded(page.items, page: 1, hasMore: page.hasMore);
    } on Object catch (error) {
      if (epoch != _epoch) return;
      final current = _state.value;
      _state.value = current is NotificationsLoaded
          ? current.copyWith(isStale: true)
          : NotificationsFailed(LoadProblem.of(error));
    }
  }

  Future<void> retry() async {
    _state.value = const NotificationsLoading();
    await reload();
  }

  Future<void> loadMore() async {
    final current = _state.value;
    if (current is! NotificationsLoaded || !current.hasMore || current.isLoadingMore) return;
    final epoch = ++_epoch;
    _state.value = current.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await _fetch(current.page + 1);
      if (epoch != _epoch) return;
      final known = {for (final item in current.items) item.id};
      _unreadCount.value = page.unreadCount;
      _state.value = NotificationsLoaded(
        [
          ...current.items,
          for (final item in page.items)
            if (!known.contains(item.id)) item,
        ],
        page: current.page + 1,
        hasMore: page.hasMore,
      );
    } on Object {
      if (epoch == _epoch) _state.value = current.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  Future<void> markRead(AppNotification notification) async {
    final current = _state.value;
    if (notification.isRead || current is! NotificationsLoaded) return;
    final now = DateTime.now();
    _state.value = current.copyWith(
      items: [for (final item in current.items) item.id == notification.id ? item.markedRead(now) : item],
    );
    _unreadCount.value = (_unreadCount.value - 1).clamp(0, 1 << 30);
    try {
      await _api.post(
        NotificationEndpoints.readOf(notification.id),
        key: IdempotencyKey('notification-read-${notification.id}'),
        options: quietOptions,
      );
    } on Object {
      await reload();
    }
  }

  Future<void> markAllRead() async {
    final current = _state.value;
    if (_unreadCount.value == 0) return;
    final now = DateTime.now();
    if (current is NotificationsLoaded) {
      _state.value = current.copyWith(items: [for (final item in current.items) item.markedRead(now)]);
    }
    _unreadCount.value = 0;
    try {
      await _api.post(
        NotificationEndpoints.readAll,
        key: IdempotencyKey.newFor('notifications-read-all'),
        options: quietOptions,
      );
    } on Object {
      await reload();
    }
  }

  Future<NotificationsPage> _fetch(int page) async {
    final response = await _api.get(NotificationEndpoints.list, queryParameters: {'page': page}, options: quietOptions);
    return NotificationsPage.fromJson(dataOf(response));
  }
}
