import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupMenuTrailing extends StatefulWidget {
  const GroupMenuTrailing({super.key, required this.kind});

  final GroupKind kind;

  @override
  State<GroupMenuTrailing> createState() => _GroupMenuTrailingState();
}

class _GroupMenuTrailingState extends State<GroupMenuTrailing> {
  static const double _maxNameWidth = 120;

  final _groups = Get.find<GroupsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_groups.open()));
  }

  Widget _invites(int count) {
    if (count == 0) return const SizedBox.shrink();
    return SangaTag.scheduled(label: count == 1 ? '1 invite' : '$count invites', icon: Icons.mail_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: SangaSpacing.sm,
      children: [
        Obx(() {
          final group = _groups.groupOf(widget.kind);
          if (group == null) return _invites(_groups.overview?.invitesOf(widget.kind).length ?? 0);
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxNameWidth),
            child: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardSubtitle),
          );
        }),
        SangaListRow.chevron,
      ],
    );
  }
}
