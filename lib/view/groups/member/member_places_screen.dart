import 'package:flutter/material.dart';
import 'package:sanga_ride/controller/rider/groups/group_controller.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/view/groups/member/member_setting_page.dart';
import 'package:sanga_ride/view/groups/widgets/group_member_gate.dart';
import 'package:sanga_ride/view/ride/widgets/place_search_sheet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class MemberPlacesScreen extends StatelessWidget {
  const MemberPlacesScreen({super.key, required this.groupId, required this.memberId});

  final String groupId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return GroupMemberGate(
      groupId: groupId,
      memberId: memberId,
      title: 'Approved places',
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
  static const int maxPlaces = 10;

  late List<ApprovedPlace> _places = [...widget.member.limits.approvedPlaces];

  String? _validate(Place place) {
    if (_places.length >= maxPlaces) return 'You can add up to $maxPlaces places.';
    if (_places.any((entry) => entry.place.isSameAs(place))) return 'That place is already on the list.';
    return null;
  }

  Future<void> _add() async {
    final place = await PlaceSearchSheet.show(
      context,
      kind: SangaStopKind.dropoff,
      hintText: 'Search for a place',
      onPick: _validate,
    );
    if (place == null || !mounted) return;
    setState(() => _places = [..._places, ApprovedPlace(id: place.placeId, label: place.name, place: place)]);
  }

  void _remove(ApprovedPlace entry) => setState(() => _places = [..._places]..remove(entry));

  @override
  Widget build(BuildContext context) {
    final name = widget.member.firstName;
    return MemberSettingPage(
      title: 'Approved places',
      group: widget.group,
      member: widget.member,
      onSave: () => saveMemberPatch(
        context: context,
        group: widget.group,
        member: widget.member,
        patch: MemberPatch(limits: widget.member.limits.copyWith(approvedPlaces: _places)),
      ),
      children: [
        Text(
          'When there are places on this list, $name’s rides have to start or end at one of them.',
          style: SangaTextStyles.body,
        ),
        SangaButton.outline(label: 'Add a place', onPressed: _places.length >= maxPlaces ? null : _add),
        if (_places.isEmpty)
          SangaInlineMessage(title: 'Anywhere goes', message: 'No places yet, so $name can ride to and from anywhere.')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SangaSpacing.sm,
            children: [
              const SangaSectionHeader('Approved places'),
              SangaListGroup(
                children: [
                  for (final entry in _places)
                    SangaListRow.place(
                      title: entry.label,
                      subtitle: entry.place.address,
                      onTap: null,
                      trailing: IconButton(
                        tooltip: 'Remove ${entry.label}',
                        onPressed: () => _remove(entry),
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: SangaColors.dangerStrong),
                      ),
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
