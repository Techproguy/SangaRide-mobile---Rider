import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/group_bindings.dart';
import 'package:sanga_ride/controller/rider/ride_history_controller.dart';
import 'package:sanga_ride/core/router/history_routes.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/model/history/history_scope.dart';
import 'package:sanga_ride/view/history/widgets/history_card.dart';
import 'package:sanga_ride/view/history/widgets/history_format.dart';
import 'package:sanga_ride/view/history/widgets/history_rebook.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryFeed extends StatefulWidget {
  const HistoryFeed({super.key, required this.status, this.scope = const HistoryScope.personal()});

  final HistoryStatus status;
  final HistoryScope scope;

  @override
  State<HistoryFeed> createState() => _HistoryFeedState();
}

class _HistoryFeedState extends State<HistoryFeed> {
  static const double _loadMoreExtent = 320;
  late final RideHistoryController _history = switch (widget.scope.groupId) {
    final String groupId => GroupControllers.rides(groupId),
    null => Get.find<RideHistoryController>(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _history.open(widget.status));
  }

  EdgeInsets get _padding => EdgeInsets.fromLTRB(
    SangaSpacing.gutter,
    SangaSpacing.md,
    SangaSpacing.gutter,
    SangaSpacing.xl + MediaQuery.paddingOf(context).bottom,
  );

  bool _onScroll(ScrollNotification notification) {
    final state = _history.feed(widget.status);
    final isIdle = state is HistoryFeedLoaded && state.more == HistoryMore.idle;
    if (isIdle && notification.metrics.extentAfter < _loadMoreExtent) _history.loadMore(widget.status);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: SangaColors.primary,
      onRefresh: () => _history.reload(widget.status),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Obx(() => _content(context, _history.feed(widget.status))),
      ),
    );
  }

  Widget _content(BuildContext context, HistoryFeedState state) {
    return switch (state) {
      HistoryFeedLoading() => _skeleton(),
      HistoryFeedFailed() => _message(
        SangaInlineMessage(
          title: 'We couldn’t load your ${widget.status.code} trips',
          message: 'Check your connection and give it another go.',
          actionLabel: 'Try again',
          onAction: () => _history.reload(widget.status),
        ),
      ),
      HistoryFeedLoaded(:final items) when items.isEmpty => _message(_empty(context)),
      HistoryFeedLoaded() => _list(context, state),
    };
  }

  Widget _skeleton() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _padding,
      children: [
        Column(
          spacing: SangaSpacing.md,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                height: 128,
                decoration: const BoxDecoration(color: SangaColors.cardMuted, borderRadius: SangaRadii.field),
              ),
          ],
        ),
      ],
    );
  }

  Widget _message(Widget message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _padding,
      children: [
        const SizedBox(height: SangaSpacing.xxl),
        message,
      ],
    );
  }

  Widget _empty(BuildContext context) {
    if (widget.scope.isGroup) return _groupEmpty();
    return switch (widget.status) {
      HistoryStatus.completed => SangaInlineMessage(
        title: 'No trips yet',
        message: 'Your finished rides and deliveries will show up here.',
        actionLabel: 'Book a ride',
        onAction: () => context.go(SangaRoutes.home),
      ),
      HistoryStatus.cancelled => const SangaInlineMessage(
        title: 'Nothing cancelled',
        message: 'Trips you or your driver cancel will show up here.',
      ),
    };
  }

  Widget _groupEmpty() {
    return switch (widget.status) {
      HistoryStatus.completed => const SangaInlineMessage(
        title: 'No group rides yet',
        message: 'Rides taken on the group’s tab show up here.',
      ),
      HistoryStatus.cancelled => const SangaInlineMessage(
        title: 'Nothing cancelled',
        message: 'Group rides that get cancelled show up here.',
      ),
    };
  }

  Widget _list(BuildContext context, HistoryFeedLoaded state) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _padding,
      itemCount: state.items.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: SangaSpacing.md),
      itemBuilder: (context, index) {
        if (index == state.items.length) return _footer(state);
        final item = state.items[index];
        return HistoryCard(
          item: item,
          whenLabel: formatHistoryWhen(context, item.occurredAt),
          onTap: () => context.push(HistoryRoutes.detailOf(item.id)),
          onRebook: item.canRebook && !widget.scope.isGroup
              ? () => rebookRide(context, item.route, item.category)
              : null,
        );
      },
    );
  }

  Widget _footer(HistoryFeedLoaded state) {
    return switch (state.more) {
      HistoryMore.loading => const Padding(
        padding: EdgeInsets.all(SangaSpacing.md),
        child: Center(child: SangaActivityIndicator(size: 24)),
      ),
      HistoryMore.failed => SangaInlineMessage(
        title: 'We couldn’t load more',
        message: 'Check your connection and give it another go.',
        actionLabel: 'Try again',
        onAction: () => _history.loadMore(widget.status),
      ),
      HistoryMore.idle => const SizedBox.shrink(),
    };
  }
}
