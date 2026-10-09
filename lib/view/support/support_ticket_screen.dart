import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_tickets_controller.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/support_copy.dart';
import 'package:sanga_ride/view/support/widgets/issue_timeline.dart';
import 'package:sanga_ride/view/support/widgets/resolution_options.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key, required this.id});

  final String id;

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final _controller = Get.find<SupportTicketsController>();
  String? _optionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.open(widget.id));
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _choose() async {
    final option = _optionId;
    if (option == null) return;
    final isChosen = await _controller.choose(option);
    if (isChosen && mounted) setState(() => _optionId = null);
  }

  Widget _header(SupportTicket ticket) {
    return Row(
      spacing: SangaSpacing.sm,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.xxs,
            children: [
              Text(ticket.typeLabel, style: SangaTextStyles.headline),
              Text(SupportCopy.ticketReference(ticket.reference), style: SangaTextStyles.body),
            ],
          ),
        ),
        SupportCopy.statusTagOf(ticket.status),
      ],
    );
  }

  Widget _decision(TicketLoaded state) {
    final ticket = state.ticket;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        const SangaSectionHeader(SupportCopy.sortThisOut),
        ResolutionOptions(
          options: ticket.resolutionOptions,
          selectedId: _optionId,
          onSelected: (id) => setState(() => _optionId = id),
        ),
        if (state.problem case final problem?) SangaNotice(message: problem.message),
      ],
    );
  }

  Widget _loaded(TicketLoaded state) {
    final ticket = state.ticket;
    final needsDecision = ticket.status == TicketStatus.actionNeeded && ticket.resolutionOptions.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xl,
      children: [
        _header(ticket),
        IssueTimeline(events: ticket.events, status: ticket.status),
        if (needsDecision) _decision(state),
      ],
    );
  }

  Widget? _footer(TicketState state) {
    if (state is! TicketLoaded) return null;
    final ticket = state.ticket;
    final needsDecision = ticket.status == TicketStatus.actionNeeded && ticket.resolutionOptions.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        if (needsDecision)
          SangaButton.primary(
            label: SupportCopy.confirm,
            isLoading: state.isChoosing,
            onPressed: _optionId == null ? null : _choose,
          ),
        if (ticket.status.isOpen || needsDecision)
          SangaButton.outline(
            label: SupportCopy.chatWithSupport,
            onPressed: () => context.push(SupportRoutes.chatOf(ticketId: ticket.id, tripId: ticket.tripId)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.detail;
      return SangaPageLayout(
        title: SupportCopy.yourReport,
        footer: _footer(state),
        children: [
          switch (state) {
            TicketLoading() => const SangaSkeleton.heights([120, 200]),
            TicketFailed(:final problem) => SangaFailureMessage(message: problem.message, onRetry: _controller.reload),
            final TicketLoaded loaded => _loaded(loaded),
          },
        ],
      );
    });
  }
}
