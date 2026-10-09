import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/support/support_help_controller.dart';
import 'package:sanga_ride/core/router/support_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final isLaunched = await launchUrl(Uri(scheme: 'tel', path: contact.phone));
    if (!isLaunched) {
      SangaToast.show(
        'We couldn’t open your phone app. You can reach us on ${contact.phone}.',
        tone: SangaToastTone.error,
      );
    }
  }

  String _chatSubtitle(SupportContact contact) {
    final minutes = contact.chatWaitMinutes;
    return minutes > 0 ? 'Chat with our team · about $minutes min wait' : 'Chat with our team';
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
                title: 'Live chat',
                subtitle: _chatSubtitle(contact),
                onTap: () => context.push(SupportRoutes.chatOf()),
              ),
            if (contact != null)
              SangaListRow(
                leading: const SangaIconBadge(size: 36, child: Icon(Icons.call_outlined)),
                title: 'Call support',
                subtitle: 'Speak with our team · ${contact.hours}',
                onTap: () => _call(contact),
              ),
            SangaListRow(
              leading: const SangaIconBadge(size: 36, child: Icon(Icons.shield_outlined)),
              title: 'Report an issue',
              subtitle: 'Send us a detailed report',
              onTap: () => context.push(SupportRoutes.reportOf()),
            ),
            SangaListRow(
              leading: const SangaIconBadge(size: 36, child: Icon(Icons.assignment_outlined)),
              title: 'My reports',
              subtitle: 'Follow up on issues you reported',
              onTap: () => context.push(SupportRoutes.tickets),
            ),
          ],
        ),
        if (contact == null || !contact.chatAvailable)
          Text(
            'Live chat is resting right now. You can still call us or send a report.',
            style: SangaTextStyles.caption,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.home;
      return SangaPageLayout(
        title: 'Contact support',
        subtitle: 'We’re here to help',
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
