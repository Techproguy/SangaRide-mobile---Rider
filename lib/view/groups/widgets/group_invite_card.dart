import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupInviteCard extends StatelessWidget {
  const GroupInviteCard({
    super.key,
    required this.invite,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final GroupInvite invite;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return SangaListGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.md,
            children: [
              Row(
                spacing: SangaSpacing.md,
                children: [
                  SangaIconBadge(size: 40, child: Icon(GroupCopy.icon(invite.kind))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: SangaSpacing.xxs,
                      children: [
                        Text(invite.groupName, style: SangaTextStyles.cardHeading),
                        Text(GroupCopy.inviteLine(invite), style: SangaTextStyles.cardSubtitle),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                spacing: SangaSpacing.sm,
                children: [
                  Expanded(
                    child: SangaButton.outline(
                      label: GroupCopy.decline,
                      size: SangaButtonSize.compact,
                      onPressed: isBusy ? null : onDecline,
                    ),
                  ),
                  Expanded(
                    child: SangaButton.primary(
                      label: GroupCopy.accept,
                      size: SangaButtonSize.compact,
                      onPressed: isBusy ? null : onAccept,
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
