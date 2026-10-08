import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/notifications_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/account/widgets/load_state.dart';
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

  void _open(AppNotification notification, String destination) {
    _controller.markRead(notification);
    context.push(destination);
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
      return const Center(
        child: SangaInlineMessage(title: 'All quiet', message: 'You’re all caught up. New updates will show up here.'),
      );
    }
    return RefreshIndicator.adaptive(
      color: SangaColors.primary,
      onRefresh: _controller.reload,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.xs, SangaSpacing.gutter, SangaSpacing.xl),
        itemCount: state.items.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: SangaSpacing.sm),
        itemBuilder: (context, index) {
          if (index == state.items.length) return _footer(state);
          final notification = state.items[index];
          final destination = NotificationRouting.destinationOf(notification);
          return NotificationRow(
            notification: notification,
            onTap: destination == null ? null : () => _open(notification, destination),
          );
        },
      ),
    );
  }

  Widget _footer(NotificationsLoaded state) {
    if (state.isLoadingMore) return const LoadingIndicator();
    if (state.loadMoreFailed) {
      return LoadFailure(message: 'We couldn’t load more.', onRetry: _controller.loadMore);
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
              Expanded(
                child: Obx(() {
                  final state = _controller.state;
                  return switch (state) {
                    NotificationsLoading() => const LoadingIndicator(),
                    NotificationsFailed() => Padding(
                      padding: const EdgeInsets.all(SangaSpacing.gutter),
                      child: LoadFailure(message: 'We couldn’t load your notifications.', onRetry: _controller.retry),
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
