import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_report_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/support_copy.dart';
import 'package:sanga_ride/view/support/widgets/issue_type_list.dart';
import 'package:sanga_ride/view/support/widgets/trip_link_list.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SupportReportScreen extends StatefulWidget {
  const SupportReportScreen({super.key, required this.issueContext, this.tripId});

  final IssueContext issueContext;
  final String? tripId;

  @override
  State<SupportReportScreen> createState() => _SupportReportScreenState();
}

class _SupportReportScreenState extends State<SupportReportScreen> {
  static const int _maxNoteLength = 500;

  final _controller = Get.find<SupportReportController>();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.open(context: widget.issueContext, tripId: widget.tripId));
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ticket = await _controller.submit(note: _note.text);
    if (ticket == null || !mounted) return;
    final isTracking = await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: SupportCopy.reportSent,
      message: SupportCopy.reportSentMessage(ticket.reference),
      actionLabel: SupportCopy.trackIt,
      secondaryLabel: SupportCopy.done,
    );
    if (!mounted) return;
    if (isTracking) {
      context.pushReplacement(SupportRoutes.ticketOf(ticket.id));
    } else {
      context.pop();
    }
  }

  Widget _section(String title, Widget child, {String? caption}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        SangaSectionHeader(title),
        if (caption != null) Text(caption, style: SangaTextStyles.caption),
        child,
      ],
    );
  }

  Widget _draft(SupportReportDraft draft) {
    final isTripScoped = draft.recentRides.isNotEmpty || draft.tripId != null;
    final unknownTripId = draft.tripId != null && draft.trip == null ? draft.tripId : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        _section(
          SupportCopy.whatHappened,
          IssueTypeList(types: draft.types, selectedId: draft.typeId, onSelected: _controller.selectType),
        ),
        if (isTripScoped)
          _section(
            SupportCopy.whichTrip,
            TripLinkList(
              rides: draft.recentRides,
              selectedId: draft.tripId,
              unknownTripId: unknownTripId,
              onSelected: _controller.selectTrip,
            ),
          ),
        SangaTextArea(
          label: SupportCopy.anythingElse,
          controller: _note,
          hintText: SupportCopy.shareAsMuch,
          maxLength: _maxNoteLength,
          minLines: 4,
          isEnabled: !draft.isSubmitting,
        ),
        if (draft.problem case final problem?) SangaNotice(message: problem.message),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.state;
      final draft = state is SupportReportDraft ? state : null;
      return SangaPageLayout(
        title: CommonCopy.reportIssue,
        footer: draft == null
            ? null
            : SangaButton.primary(
                label: SupportCopy.submitReport,
                isLoading: draft.isSubmitting,
                onPressed: draft.typeId == null ? null : _submit,
              ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.lg,
            children: [
              _section(
                SupportCopy.whatsThisAbout,
                SangaChoiceChips<IssueContext>(
                  options: [
                    for (final value in IssueContext.values)
                      SangaSelectOption(value, SupportCopy.contextLabelOf(value)),
                  ],
                  value: _controller.context,
                  onChanged: _controller.changeContext,
                ),
              ),
              switch (state) {
                SupportReportLoading() => const SangaSkeleton.heights([56, 56, 56]),
                SupportReportFailed(:final problem) => SangaFailureMessage(
                  message: problem.message,
                  onRetry: _controller.reload,
                ),
                final SupportReportDraft draft => _draft(draft),
              },
            ],
          ),
        ],
      );
    });
  }
}
