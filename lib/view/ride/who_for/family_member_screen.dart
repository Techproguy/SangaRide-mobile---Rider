import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/who_for/widgets/ride_for_list_body.dart';
import 'package:sanga_ride/view/ride/who_for/widgets/who_for_avatar.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class FamilyMemberScreen extends StatefulWidget {
  const FamilyMemberScreen({super.key});

  @override
  State<FamilyMemberScreen> createState() => _FamilyMemberScreenState();
}

class _FamilyMemberScreenState extends State<FamilyMemberScreen> {
  final _flow = Get.find<RideForController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _flow.loadFamily());
  }

  void _confirm() {
    _flow.confirmMember();
    context.pop(true);
  }

  String _subtitleOf(FamilyMember member) => member.isYou ? 'You · ${member.relationship}' : member.relationship;

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Who’s riding?',
      footer: Obx(() => SangaButton.primary(label: 'Confirm', onPressed: _flow.pickedMember == null ? null : _confirm)),
      children: [
        Obx(
          () => RideForListBody<FamilyMember>(
            state: _flow.family,
            emptyTitle: 'No family members yet',
            emptyMessage: 'Create or join a family group from the menu, then book rides for everyone in it here.',
            failedTitle: 'We couldn’t load your family',
            onRetry: _flow.loadFamily,
            builder: (context, members) => Column(
              spacing: SangaSpacing.md,
              children: [
                for (final member in members)
                  SangaOptionCard(
                    leading: WhoForAvatar(name: member.name),
                    title: member.isYou ? '${member.name} (You)' : member.name,
                    subtitle: _subtitleOf(member),
                    isSelected: _flow.pickedMember?.id == member.id,
                    onTap: () => _flow.pickMember(member),
                  ),
                if (_flow.pickedMember case final member?)
                  SangaCallout.info(
                    lines: [
                      SangaCalloutLine(
                        icon: SangaAssets.shield,
                        text:
                            'This ride can be paid from ${member.groupName}’s wallet, as long as ${member.isYou ? 'your' : '${member.firstName}’s'} limits allow it.',
                      ),
                    ],
                  ).animate().fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
