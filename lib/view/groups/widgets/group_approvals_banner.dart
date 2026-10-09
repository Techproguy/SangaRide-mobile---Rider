import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupApprovalsBanner extends StatelessWidget {
  const GroupApprovalsBanner({super.key, required this.approvals, required this.onTap});

  final List<GroupApproval> approvals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SangaInfoTile.compact(
      icon: SangaAssets.bell,
      title: GroupCopy.approvalsTitle(approvals.length),
      subtitle: GroupCopy.approvalsSubtitle(approvals),
      actionLabel: GroupCopy.review,
      onTap: onTap,
    );
  }
}
