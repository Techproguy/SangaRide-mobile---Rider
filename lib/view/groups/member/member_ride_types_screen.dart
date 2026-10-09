import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/controller/rider/ride_request_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/groups/member/member_setting_page.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberRideTypesScreen extends StatelessWidget {
  const MemberRideTypesScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return GroupMemberGate(
      groupId: groupId,
      memberId: memberId,
      title: GroupCopy.rideTypesTitle,
      builder: (context, group, detail, member) => _Form(group: group, member: member),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.group, required this.member});

  final GroupController group;
  final GroupMember member;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _booking = Get.find<RideRequestController>();
  Set<String>? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_booking.loadOptions()));
  }

  Set<String> _selectionOf(List<RideOption> options) =>
      _selected ??
      {
        ...(widget.member.limits.rideTypes ?? [for (final option in options) option.id]),
      };

  void _toggle(List<RideOption> options, RideOption option, bool isOn) {
    final next = {..._selectionOf(options)};
    if (isOn) {
      next.add(option.id);
    } else {
      next.remove(option.id);
    }
    setState(() => _selected = next);
  }

  void _save(List<RideOption> options) {
    final selection = _selectionOf(options);
    final isEverything = options.every((option) => selection.contains(option.id));
    saveMemberPatch(
      context: context,
      group: widget.group,
      member: widget.member,
      patch: MemberPatch(
        limits: widget.member.limits.copyWith(
          rideTypes: () => isEverything
              ? null
              : [
                  for (final option in options)
                    if (selection.contains(option.id)) option.id,
                ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final options = _booking.options.toList();
      final selection = _selectionOf(options);
      return MemberSettingPage(
        title: GroupCopy.rideTypesTitle,
        group: widget.group,
        member: widget.member,
        canSave: options.isNotEmpty && selection.isNotEmpty,
        onSave: () => _save(options),
        children: [
          Text(GroupCopy.pickRideTypes(widget.member.firstName), style: SangaTextStyles.body),
          if (options.isEmpty && _booking.isLoadingOptions)
            const Center(child: SangaActivityIndicator(size: 32))
          else if (options.isEmpty)
            SangaFailureMessage(
              title: GroupCopy.rideTypesLoadFailed,
              message: CommonCopy.connectionBody,
              onRetry: _booking.loadOptions,
            )
          else
            SangaListGroup(
              children: [
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md),
                    child: SangaToggleRow(
                      leading: SizedBox(
                        width: 56,
                        child: Image(image: option.category.image, fit: BoxFit.contain),
                      ),
                      title: option.name,
                      subtitle: option.description,
                      value: selection.contains(option.id),
                      onChanged: (isOn) => _toggle(options, option, isOn),
                    ),
                  ),
              ],
            ),
        ],
      );
    });
  }
}
