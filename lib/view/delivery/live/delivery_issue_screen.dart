import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/trip/delivery_issue_controller.dart';
import 'package:sanga_ride/core/router/delivery_live_routes.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/live/widgets/issue_reason_list.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryIssueScreen extends StatefulWidget {
  const DeliveryIssueScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<DeliveryIssueScreen> createState() => _DeliveryIssueScreenState();
}

class _DeliveryIssueScreenState extends State<DeliveryIssueScreen> {
  final _issue = Get.find<DeliveryIssueController>();
  final _note = TextEditingController();
  DeliveryIssueReason? _reason;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_prepare()));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    await _issue.open(widget.tripId);
    if (!mounted) return;
    _issue.backToReasons();
    if (_issue.hasOpenIssue) context.pushReplacement(DeliveryLiveRoutes.issueStatusOf(widget.tripId));
  }

  bool get _isReady => DeliveryIssueRules.isReady(_reason, _note.text);

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;
    FocusScope.of(context).unfocus();
    final isSent = await _issue.submit(reason, _note.text);
    if (!mounted) return;
    if (isSent) {
      context.pushReplacement(DeliveryLiveRoutes.issueStatusOf(widget.tripId));
      return;
    }
    if (_issue.state case IssueSubmitFailed(:final problem) when problem == DeliveryIssueProblem.tripEnded) {
      Toast.info(problem.message);
      DeliveryLiveRoutes.popToTrip(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _issue.state;
      final isSubmitting = state is IssueSubmitting;
      return PopScope(
        canPop: !isSubmitting,
        child: SangaPageLayout(
          title: 'Report an issue',
          footer: ListenableBuilder(
            listenable: _note,
            builder: (context, _) => SangaButton.primary(
              label: 'Report an issue',
              isLoading: isSubmitting,
              onPressed: _isReady ? _submit : null,
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: SangaSpacing.lg,
              children: [
                const Text('What’s going on with your delivery?', style: SangaTextStyles.body),
                IssueReasonList(
                  selected: _reason,
                  isEnabled: !isSubmitting,
                  onSelect: (reason) => setState(() => _reason = reason),
                ),
                if (_reason case final DeliveryIssueReason reason) ...[
                  if (reason.pointsToSafety)
                    _SafetyNotice(onOpen: () => unawaited(context.push(SafetyRoutes.centreOf(tripId: widget.tripId)))),
                  SangaTextArea(
                    label: reason.needsNote ? 'Tell us what happened' : 'Anything else we should know? (optional)',
                    controller: _note,
                    hintText: 'Share as much as you can',
                    maxLength: DeliveryIssueRules.maxNoteLength,
                    minLines: 3,
                    isEnabled: !isSubmitting,
                  ),
                  if (reason.needsNote) ListenableBuilder(listenable: _note, builder: (context, _) => _lengthHint()),
                ],
                if (state case IssueSubmitFailed(:final problem))
                  SangaNotice(message: problem.message, icon: Icons.error_outline_rounded),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _lengthHint() {
    final length = _note.text.trim().length;
    if (length == 0 || length >= DeliveryIssueRules.minOtherNoteLength) return const SizedBox.shrink();
    return Text(
      'Add a bit more, at least ${DeliveryIssueRules.minOtherNoteLength} characters.',
      style: SangaTextStyles.caption,
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xs,
      children: [
        const SangaNotice(
          message: 'If you’re in danger, use Safety to call for help right away.',
          icon: Icons.shield_outlined,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onOpen,
            child: Text('Open Safety', style: SangaTextStyles.label.copyWith(color: SangaColors.primary)),
          ),
        ),
      ],
    );
  }
}
