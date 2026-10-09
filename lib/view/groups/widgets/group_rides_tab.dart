import 'package:flutter/material.dart';
import 'package:sanga_ride/controller/rider/groups/group_bindings.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/model/history/history_scope.dart';
import 'package:sanga_ride/view/groups/group_copy.dart';
import 'package:sanga_ride/view/history/widgets/history_feed.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class GroupRidesTab extends StatefulWidget {
  const GroupRidesTab({super.key, required this.detail});

  final GroupDetail detail;

  @override
  State<GroupRidesTab> createState() => _GroupRidesTabState();
}

class _GroupRidesTabState extends State<GroupRidesTab> {
  late final _rides = GroupControllers.rides(widget.detail.id);
  late final HistoryScope _scope = HistoryScope.group(widget.detail.id);
  HistoryStatus _status = HistoryStatus.completed;
  late String? _memberId = _rides.memberId;

  List<GroupMember> get _members => [
    for (final member in widget.detail.members)
      if (!member.isInvited) member,
  ];

  void _selectMember(String? id) {
    setState(() => _memberId = id);
    _rides.selectMember(id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChipRow(
          children: [
            for (final status in HistoryStatus.tabs)
              SangaChoiceChip(
                label: status.label,
                isSelected: status == _status,
                onSelected: (_) => setState(() => _status = status),
              ),
          ],
        ),
        if (widget.detail.canManage)
          _ChipRow(
            children: [
              SangaChoiceChip(
                label: GroupCopy.everyone,
                isSelected: _memberId == null,
                onSelected: (_) => _selectMember(null),
              ),
              for (final member in _members)
                SangaChoiceChip(
                  label: member.firstName,
                  isSelected: _memberId == member.id,
                  onSelected: (_) => _selectMember(member.id),
                ),
            ],
          ),
        Expanded(
          child: SangaHandoff(
            value: _status,
            child: HistoryFeed(status: _status, scope: _scope),
          ),
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.gutter, vertical: SangaSpacing.sm),
      child: Row(spacing: SangaSpacing.sm, children: children),
    );
  }
}
