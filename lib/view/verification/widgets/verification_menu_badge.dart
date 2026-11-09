import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/account/account_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerificationMenuBadge extends StatefulWidget {
  const VerificationMenuBadge({super.key});

  @override
  State<VerificationMenuBadge> createState() => _VerificationMenuBadgeState();
}

class _VerificationMenuBadgeState extends State<VerificationMenuBadge> {
  final _controller = Get.find<AccountController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.loadIfStale());
    });
  }

  Widget _tag(VerificationStatus status) {
    final label = AccountCopy.verificationLabel(status);
    return switch (status) {
      VerificationStatus.verified => SangaTag.success(label: label),
      VerificationStatus.pending => SangaTag.scheduled(label: label, icon: Icons.hourglass_top_rounded),
      VerificationStatus.rejected ||
      VerificationStatus.actionNeeded => SangaTag.urgent(label: label, icon: Icons.error_outline_rounded),
      VerificationStatus.unverified => SangaTag.warning(label: label, icon: Icons.info_outline_rounded),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = _controller.account?.verification;
      return status == null ? const SizedBox.shrink() : _tag(status);
    });
  }
}
