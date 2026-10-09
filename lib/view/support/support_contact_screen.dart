import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_help_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/safety/widgets/dial_number.dart';
import 'package:sanga_ride/view/support/support_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SupportContactScreen extends StatefulWidget {
  const SupportContactScreen({super.key});

  @override
  State<SupportContactScreen> createState() => _SupportContactScreenState();
}

class _SupportContactScreenState extends State<SupportContactScreen> {
  final _controller = Get.find<SupportHelpController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.loadHome());
    });
  }

  Future<void> _call(SupportContact contact) async {
    await dialNumber(contact.phone, failureMessage: SupportCopy.callFailed(contact.phone));
  }

  String _chatSubtitle(SupportContact contact) {
    final minutes = contact.chatWaitMinutes;
    return minutes > 0 ? SupportCopy.chatWithTeamWait(minutes) : SupportCopy.chatWithTeam;
  }

  Widget _options(SupportContact? contact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        SangaListGroup(
          children: [
            if (contact != null && contact.chatAvailable)
              SangaListRow(
                leading: const SangaIconBadge(size: 36, child: Icon(Icons.chat_bubble_outline_rounded)),
                title: SupportCopy.liveChat,
                subtitle: _chatSubtitle(contact),
                onTap: () => context.push(SupportRoutes.chatOf()),
              ),
            if (contact != null)
              SangaListRow(
                leading: const SangaIconBadge(size: 36, child: Icon(Icons.call_outlined)),
                title: SupportCopy.callSupport,
                subtitle: SupportCopy.speakWithTeam(contact.hours),
                onTap: () => _call(contact),
              ),
            SangaListRow(
              leading: const SangaIconBadge(size: 36, child: Icon(Icons.shield_outlined)),
              title: CommonCopy.reportIssue,
              subtitle: SupportCopy.sendDetailedReport,
              onTap: () => context.push(SupportRoutes.reportOf()),
            ),
            SangaListRow(
              leading: const SangaIconBadge(size: 36, child: Icon(Icons.assignment_outlined)),
              title: SupportCopy.myReports,
              subtitle: SupportCopy.followUp,
              onTap: () => context.push(SupportRoutes.tickets),
            ),
          ],
        ),
        if (contact == null || !contact.chatAvailable) Text(SupportCopy.chatResting, style: SangaTextStyles.caption),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.home;
      return SangaPageLayout(
        title: SupportCopy.contactSupport,
        subtitle: SupportCopy.hereToHelp,
        children: [
          switch (state) {
            SupportHomeLoading() => const SangaSkeleton.heights([56, 56, 56, 56]),
            SupportHomeFailed(:final problem) => SangaFailureMessage(
              message: problem.message,
              onRetry: _controller.loadHome,
            ),
            SupportHomeLoaded(:final home) => _options(home.contact),
          },
        ],
      );
    });
  }
}
