import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/delivery_issue_controller.dart';
import 'package:sanga_ride/core/router/delivery_live_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/live/widgets/issue_info_card.dart';
import 'package:sanga_ride/view/delivery/live/widgets/issue_resolution_list.dart';
import 'package:sanga_ride/view/delivery/live/widgets/issue_timeline_entries.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryIssueStatusScreen extends StatefulWidget {
  const DeliveryIssueStatusScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<DeliveryIssueStatusScreen> createState() => _DeliveryIssueStatusScreenState();
}

class _DeliveryIssueStatusScreenState extends State<DeliveryIssueStatusScreen> {
  static const List<({IconData icon, String text})> _openRows = [
    (icon: Icons.support_agent_rounded, text: 'Our team is looking into this right now'),
    (icon: Icons.refresh_rounded, text: 'This page updates by itself, so you can leave it open'),
    (icon: Icons.schedule_rounded, text: 'Most issues are sorted within a few minutes'),
  ];

  final _issue = Get.find<DeliveryIssueController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_issue.open(widget.tripId)));
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _resolve(DeliveryIssueState state) async {
    if (state is IssueActionNeeded && state.selectedId == 'cancel') {
      final isConfirmed = await showSangaPromptSheet(
        context: context,
        icon: Icons.cancel_outlined,
        title: 'Cancel this delivery?',
        message: 'Your driver will stop and the delivery will end.',
        actionLabel: 'Cancel delivery',
        dismissLabel: 'Keep it',
      );
      if (!isConfirmed || !mounted) return;
    }
    await _issue.resolve();
  }

  Widget? _footer(DeliveryIssueState state) {
    return switch (state) {
      IssueActionNeeded(:final selectedId) => SangaButton.primary(
        label: 'Confirm selected option',
        onPressed: selectedId == null ? null : () => unawaited(_resolve(state)),
      ),
      IssueResolving() => SangaButton.primary(label: 'Confirm selected option', isLoading: true, onPressed: null),
      IssueResolutionFailed() => SangaButton.primary(label: 'Try again', onPressed: () => unawaited(_resolve(state))),
      IssueResolved() => SangaButton.primary(
        label: 'Back to my delivery',
        onPressed: () => DeliveryLiveRoutes.popToTrip(context),
      ),
      IssueInProgress() => SangaButton.muted(
        label: 'Back to my delivery',
        onPressed: () => DeliveryLiveRoutes.popToTrip(context),
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _issue.state;
      return PopScope(
        canPop: state is! IssueResolving,
        child: SangaPageLayout(
          title: 'Report an issue',
          subtitle: switch (state) {
            IssueLoaded(:final issue) => 'Reference ${issue.reference}',
            _ => null,
          },
          footer: _footer(state),
          children: [_body(state)],
        ),
      );
    });
  }

  Widget _body(DeliveryIssueState state) {
    return switch (state) {
      IssueLoaded(:final issue) => _IssueBody(issue: issue, state: state, onSelect: _issue.selectOption),
      IssueUnavailable(:final problem) => SangaFailureMessage(
        title: problem.title,
        message: problem.message,
        onRetry: problem.canRetry ? () => unawaited(_issue.open(widget.tripId)) : null,
      ),
      IssueIdle() => SangaEmptyMessage(
        icon: Icons.flag_outlined,
        title: 'No report yet',
        message: 'You haven’t reported anything on this delivery.',
        actionLabel: 'Report an issue',
        onAction: () => context.pushReplacement(DeliveryLiveRoutes.issueOf(widget.tripId)),
      ),
      IssueLoading() || IssueSubmitting() || IssueSubmitFailed() => const SangaSkeleton.heights([120, 72, 72]),
    };
  }
}

class _IssueBody extends StatelessWidget {
  const _IssueBody({required this.issue, required this.state, required this.onSelect});

  final DeliveryIssue issue;
  final IssueLoaded state;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xl,
      children: [
        SangaTimeline(entries: IssueTimelineEntries.of(issue), isAccented: state is IssueResolved),
        if (state is IssueInProgress && state.isStale)
          const SangaNotice(
            message: 'You’re offline. We’ll refresh this as soon as you’re back.',
            tone: SangaTone.neutral,
            icon: Icons.wifi_off_rounded,
          ),
        if (state is IssueInProgress) const IssueInfoCard(rows: _DeliveryIssueStatusScreenState._openRows),
        if (state is IssueActionNeeded || state is IssueResolving || state is IssueResolutionFailed)
          IssueResolutionList(options: issue.options, selectedId: _selectedOf(state), onSelect: onSelect),
        if (state case IssueResolutionFailed(:final problem))
          SangaNotice(message: problem.message, tone: SangaTone.warning),
      ],
    );
  }

  String? _selectedOf(IssueLoaded state) => switch (state) {
    IssueActionNeeded(:final selectedId) => selectedId,
    IssueResolving(:final optionId) => optionId,
    IssueResolutionFailed(:final optionId) => optionId,
    _ => null,
  };
}
