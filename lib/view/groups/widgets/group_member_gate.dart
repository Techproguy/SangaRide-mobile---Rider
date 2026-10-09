import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/groups/group_bindings.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupGate extends StatefulWidget {
  const GroupGate({super.key, required this.groupId, required this.title, required this.builder});

  final String groupId;
  final String title;
  final Widget Function(BuildContext context, GroupController group, GroupDetail detail) builder;

  @override
  State<GroupGate> createState() => _GroupGateState();
}

class _GroupGateState extends State<GroupGate> {
  late final GroupController _group = GroupControllers.group(widget.groupId);

  @override
  void initState() {
    super.initState();
    if (_group.detail == null) WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_group.open()));
  }

  Widget _page(Widget child) => SangaPageLayout(title: widget.title, children: [child]);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _group.state;
      return switch (state) {
        GroupDetailLoading() => _page(const SangaSkeleton.heights([72, 56, 56, 56])),
        GroupDetailFailed(:final failure) => _page(
          SangaFailureMessage(
            title: failure.title,
            message: failure.message,
            icon: failure.isNotFound ? Icons.search_off_rounded : Icons.cloud_off_rounded,
            retryLabel: failure.isNotFound ? GroupCopy.back : GroupCopy.tryAgain,
            onRetry: failure.isNotFound ? context.pop : _group.reload,
          ),
        ),
        GroupDetailLoaded(:final detail) => widget.builder(context, _group, detail),
      };
    });
  }
}

class GroupMemberGate extends StatelessWidget {
  const GroupMemberGate({
    super.key,
    required this.groupId,
    required this.memberId,
    required this.title,
    required this.builder,
  });

  final String groupId;
  final String memberId;
  final String title;
  final Widget Function(BuildContext context, GroupController group, GroupDetail detail, GroupMember member) builder;

  @override
  Widget build(BuildContext context) {
    return GroupGate(
      groupId: groupId,
      title: title,
      builder: (context, group, detail) {
        final member = detail.memberOf(memberId);
        if (member == null) {
          return SangaPageLayout(
            title: title,
            children: [
              SangaEmptyMessage(
                icon: Icons.person_off_outlined,
                title: GroupCopy.notInGroupTitle,
                message: GroupCopy.notInGroupMessage,
                actionLabel: GroupCopy.back,
                onAction: context.pop,
              ),
            ],
          );
        }
        return builder(context, group, detail, member);
      },
    );
  }
}
