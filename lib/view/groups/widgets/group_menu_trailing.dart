import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupMenuTrailing extends StatefulWidget {
  const GroupMenuTrailing({super.key, required this.kind});

  final GroupKind kind;

  @override
  State<GroupMenuTrailing> createState() => _GroupMenuTrailingState();
}

class _GroupMenuTrailingState extends State<GroupMenuTrailing> {
  final _groups = Get.find<GroupsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_groups.openIfStale()));
  }

  Widget _invites(int count) {
    if (count == 0) return const SizedBox.shrink();
    return SangaCountBadge(label: '$count', semanticLabel: GroupCopy.invitesCount(count));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_groups.groupOf(widget.kind) != null) return const SizedBox.shrink();
      return _invites(_groups.overview?.invitesOf(widget.kind).length ?? 0);
    });
  }
}
