import 'package:sanga_ride/model/account/load_problem.dart';
import 'package:sanga_ride/model/notifications/app_notification.dart';

sealed class NotificationsState {
  const NotificationsState();
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsFailed extends NotificationsState {
  const NotificationsFailed(this.problem);

  final LoadProblem problem;
}

final class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(
    this.items, {
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.isStale = false,
  });

  final List<AppNotification> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final bool isStale;

  NotificationsLoaded copyWith({
    List<AppNotification>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    bool? isStale,
  }) => NotificationsLoaded(
    items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    isStale: isStale ?? this.isStale,
  );
}
