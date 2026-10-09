import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    super.key,
    required this.approval,
    required this.isDeciding,
    required this.isLocked,
    required this.onApprove,
    required this.onDecline,
    required this.onExpired,
  });

  final GroupApproval approval;
  final bool isDeciding;
  final bool isLocked;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context) {
    final purpose = approval.purpose;
    return SangaListGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.md,
            children: [
              Text(GroupCopy.approvalLine(approval), style: SangaTextStyles.cardTitle),
              SangaRouteSummary(pickup: approval.pickup, dropoff: approval.dropoff),
              if (purpose != null) Text(GroupCopy.forPurpose(purpose), style: SangaTextStyles.cardSubtitle),
              Text(GroupCopy.fare(approval.fare), style: SangaTextStyles.cardValue),
              if (approval.expiresAt case final expiresAt?) _ExpiryLine(expiresAt: expiresAt, onExpired: onExpired),
              Row(
                spacing: SangaSpacing.sm,
                children: [
                  Expanded(
                    child: SangaButton.outline(
                      label: GroupCopy.decline,
                      size: SangaButtonSize.compact,
                      onPressed: isLocked ? null : onDecline,
                    ),
                  ),
                  Expanded(
                    child: SangaButton.primary(
                      label: GroupCopy.approve,
                      size: SangaButtonSize.compact,
                      isLoading: isDeciding,
                      onPressed: isLocked ? null : onApprove,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpiryLine extends StatelessWidget {
  const _ExpiryLine({required this.expiresAt, required this.onExpired});

  final DateTime expiresAt;
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context) {
    return SangaCountdown.server(
      endsAt: expiresAt,
      onFinished: onExpired,
      builder: (context, remaining) => Text(
        remaining == Duration.zero ? GroupCopy.requestClosed : GroupCopy.approvalExpiry(remaining),
        style: SangaTextStyles.caption,
      ),
    );
  }
}
