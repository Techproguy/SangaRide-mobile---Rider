import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_tickets_controller.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/account/widgets/load_state.dart';
import 'package:sanga_ride/view/support/widgets/ticket_row.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  static const double _loadMoreExtent = 320;

  final _controller = Get.find<SupportTicketsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.loadList());
    });
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < _loadMoreExtent) unawaited(_controller.loadMore());
    return false;
  }

  Widget _list(TicketsLoaded state) {
    if (state.items.isEmpty) {
      return SangaInlineMessage(
        title: 'No reports yet',
        message: 'If something goes wrong on a trip, you can tell us here.',
        actionLabel: 'Report an issue',
        onAction: () => context.push(SupportRoutes.reportOf()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SangaListGroup(
          children: [
            for (final ticket in state.items)
              TicketRow(ticket: ticket, onTap: () => context.push(SupportRoutes.ticketOf(ticket.id))),
          ],
        ),
        if (state.isLoadingMore) const LoadingIndicator(),
        if (state.loadMoreFailed)
          LoadFailure(
            title: 'We couldn’t load more',
            message: SupportProblem.connection.message,
            onRetry: _controller.loadMore,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.list;
      return NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: SangaPageLayout(
          title: 'My reports',
          footer: SangaButton.outline(
            label: 'Report an issue',
            onPressed: () => context.push(SupportRoutes.reportOf()),
          ),
          children: [
            switch (state) {
              TicketsLoading() => const LoadingIndicator(),
              TicketsFailed() => LoadFailure(
                message: SupportProblem.connection.message,
                onRetry: _controller.retryList,
              ),
              final TicketsLoaded loaded => _list(loaded),
            },
          ],
        ),
      );
    });
  }
}
