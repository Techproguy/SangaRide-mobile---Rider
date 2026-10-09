import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/wallet/wallet_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    super.key,
    required this.approval,
    required this.isDeciding,
    required this.isLocked,
    required this.onApprove,
    required this.onDecline,
  });

  final GroupApproval approval;
  final bool isDeciding;
  final bool isLocked;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

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
              if (purpose != null) Text('For: $purpose', style: SangaTextStyles.cardSubtitle),
              Text('Fare ${WalletFormat.money(approval.fare)}', style: SangaTextStyles.cardValue),
              Row(
                spacing: SangaSpacing.sm,
                children: [
                  Expanded(
                    child: SangaButton.outline(
                      label: 'Decline',
                      size: SangaButtonSize.compact,
                      onPressed: isLocked ? null : onDecline,
                    ),
                  ),
                  Expanded(
                    child: SangaButton.primary(
                      label: 'Approve',
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
