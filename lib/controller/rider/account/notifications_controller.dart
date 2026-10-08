import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/notification_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class NotificationsController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<NotificationsState> _state = Rx<NotificationsState>(const NotificationsLoading());
  final RxInt _unreadCount = 0.obs;

  NotificationsState get state => _state.value;

  int get unreadCount => _unreadCount.value;

  Future<void> reload() async {
    try {
      final page = await _fetch(1);
      _unreadCount.value = page.unreadCount;
      _state.value = NotificationsLoaded(page.items, page: 1, hasMore: page.hasMore);
    } catch (error) {
      log('notifications load failed: $error');
      if (_state.value is! NotificationsLoaded) _state.value = const NotificationsFailed();
    }
  }

  Future<void> retry() async {
    _state.value = const NotificationsLoading();
    await reload();
  }

  Future<void> loadMore() async {
    final current = _state.value;
    if (current is! NotificationsLoaded || !current.hasMore || current.isLoadingMore) return;
    _state.value = current.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await _fetch(current.page + 1);
      _unreadCount.value = page.unreadCount;
      _state.value = NotificationsLoaded(
        [...current.items, ...page.items],
        page: current.page + 1,
        hasMore: page.hasMore,
      );
    } catch (error) {
      log('notifications page failed: $error');
      _state.value = current.copyWith(isLoadingMore: false, loadMoreFailed: true);
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
      await _api.post(NotificationEndpoints.readOf(notification.id), options: quietOptions);
    } catch (error) {
      log('mark read failed: $error');
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
      await _api.post(NotificationEndpoints.readAll, options: quietOptions);
    } catch (error) {
      log('mark all read failed: $error');
      await reload();
    }
  }

  Future<NotificationsPage> _fetch(int page) async {
    final response = await _api.get(NotificationEndpoints.list, queryParameters: {'page': page}, options: quietOptions);
    return NotificationsPage.fromJson(dataOf(response));
  }
}
