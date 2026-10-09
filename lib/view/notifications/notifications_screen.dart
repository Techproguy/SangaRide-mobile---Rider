import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/notifications_controller.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/notifications/notification_routing.dart';
import 'package:sanga_ride/view/notifications/widgets/notification_row.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const double _loadMoreThreshold = 320;

  final _controller = Get.find<NotificationsController>();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.reload();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < _loadMoreThreshold) _controller.loadMore();
  }

  void _open(AppNotification notification) {
    final activeTripId = Get.find<SessionRestore>().meState?.activeTrip?.id;
    final destination = NotificationRouting.destinationOf(notification, activeTripId: activeTripId);
    if (destination == null) return;
    _controller.markRead(notification);
    context.push(destination);
  }

  Widget _permissionNotice() {
    final permissions = Get.find<PermissionCenter>();
    return Obx(() {
      final access = permissions.accessOf(PermissionKind.notifications);
      if (access.isUsable || access.canAskAgain) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, 0, SangaSpacing.gutter, SangaSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.xs,
          children: [
            const SangaNotice(
              tone: SangaTone.warning,
              icon: Icons.notifications_off_outlined,
              message: 'Notifications are off, so updates only show up here. Turn them on in Settings.',
            ),
            SangaButton.outline(
              label: 'Open Settings',
              size: SangaButtonSize.compact,
              onPressed: permissions.openSettings,
            ),
          ],
        ),
      );
    });
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.md, SangaSpacing.gutter, SangaSpacing.sm),
      child: Row(
        children: [
          const SangaCircleButton.back(),
          const Expanded(
            child: Text('Notifications', textAlign: TextAlign.center, style: SangaTextStyles.toolbarTitle),
          ),
          Obx(
            () => SizedBox(
              width: 41,
              child: _controller.unreadCount == 0
                  ? null
                  : IconButton(
                      tooltip: 'Mark all as read',
                      padding: EdgeInsets.zero,
                      onPressed: _controller.markAllRead,
                      icon: const Icon(Icons.done_all_rounded, color: SangaColors.primary),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(NotificationsLoaded state) {
    if (state.items.isEmpty) {
      return SangaRefreshList.children(
        onRefresh: _controller.reload,
        children: const [
          SangaEmptyMessage(
            icon: Icons.notifications_none_rounded,
            title: 'All quiet',
            message: 'You’re all caught up. New updates will show up here.',
          ),
        ],
      );
    }
    final staleOffset = state.isStale ? 1 : 0;
    return SangaRefreshList(
      onRefresh: _controller.reload,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.xs, SangaSpacing.gutter, SangaSpacing.xl),
        itemCount: state.items.length + 1 + staleOffset,
        separatorBuilder: (context, index) => const SizedBox(height: SangaSpacing.sm),
        itemBuilder: (context, rawIndex) {
          if (state.isStale && rawIndex == 0) return SangaStaleNotice(onRetry: _controller.reload);
          final index = rawIndex - staleOffset;
          if (index == state.items.length) return _footer(state);
          final notification = state.items[index];
          return NotificationRow(
            notification: notification,
            onTap: NotificationRouting.hasDestination(notification) ? () => _open(notification) : null,
          );
        },
      ),
    );
  }

  Widget _footer(NotificationsLoaded state) {
    if (state.isLoadingMore) return const SangaSkeleton.heights([72]);
    if (state.loadMoreFailed) {
      return SangaFailureMessage(
        title: 'We couldn’t load more',
        message: LoadProblem.connection.message,
        onRetry: _controller.loadMore,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        backgroundColor: SangaColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              _permissionNotice(),
              Expanded(
                child: Obx(() {
                  final state = _controller.state;
                  return switch (state) {
                    NotificationsLoading() => const Padding(
                      padding: EdgeInsets.all(SangaSpacing.gutter),
                      child: SangaSkeleton.list(count: 4, height: 80),
                    ),
                    NotificationsFailed(:final problem) => Padding(
                      padding: const EdgeInsets.all(SangaSpacing.gutter),
                      child: SangaFailureMessage(
                        title: 'We couldn’t load your notifications',
                        message: problem.message,
                        onRetry: _controller.retry,
                      ),
                    ),
                    NotificationsLoaded() => _list(state),
                  };
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
