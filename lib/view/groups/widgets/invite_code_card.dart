import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/widgets/invite_code_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({
    super.key,
    required this.kind,
    required this.groupName,
    required this.code,
    required this.onCopied,
  });

  final GroupKind kind;
  final String groupName;
  final String code;
  final VoidCallback onCopied;

  String get _shareText => GroupCopy.shareText(kind: kind, groupName: groupName, formattedCode: InviteCode.group(code));

  @override
  Widget build(BuildContext context) {
    return SangaSectionCard(
      title: GroupCopy.shareYourCode,
      subtitle: GroupCopy.anyoneCanAsk(groupName),
      children: [
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.md,
            children: [
              Text(
                InviteCode.group(code),
                textAlign: TextAlign.center,
                style: SangaTextStyles.display.copyWith(color: SangaColors.primary, letterSpacing: 4),
              ),
              Row(
                spacing: SangaSpacing.sm,
                children: [
                  Expanded(
                    child: SangaButton.outline(
                      label: GroupCopy.copy,
                      size: SangaButtonSize.compact,
                      onPressed: onCopied,
                    ),
                  ),
                  Expanded(
                    child: SangaButton.primary(
                      label: GroupCopy.share,
                      size: SangaButtonSize.compact,
                      onPressed: () => SharePlus.instance.share(ShareParams(text: _shareText)),
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
