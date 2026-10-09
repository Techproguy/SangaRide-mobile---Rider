import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_tickets_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/support_copy.dart';
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
      return SangaEmptyMessage(
        icon: Icons.assignment_outlined,
        title: SupportCopy.noReports,
        message: SupportCopy.noReportsMessage,
        actionLabel: CommonCopy.reportIssue,
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
        if (state.isStale) SangaStaleNotice(onRetry: _controller.loadList),
        if (state.isLoadingMore) const SangaSkeleton.heights([56]),
        if (state.loadMoreFailed)
          SangaFailureMessage(
            title: CommonCopy.loadMoreFailed,
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
          title: SupportCopy.myReports,
          footer: SangaButton.outline(
            label: CommonCopy.reportIssue,
            onPressed: () => context.push(SupportRoutes.reportOf()),
          ),
          children: [
            switch (state) {
              TicketsLoading() => const SangaSkeleton.heights([56, 56, 56]),
              TicketsFailed(:final problem) => SangaFailureMessage(
                message: problem.message,
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
