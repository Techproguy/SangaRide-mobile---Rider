import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class SupportCopy {
  static IconData topicIconOf(SupportTopicIcon icon) => switch (icon) {
    SupportTopicIcon.flight => Icons.flight_takeoff_rounded,
    SupportTopicIcon.accident => Icons.car_crash_outlined,
    SupportTopicIcon.lostItem => Icons.luggage_outlined,
    SupportTopicIcon.route => Icons.route_outlined,
    SupportTopicIcon.cancel => Icons.highlight_off_rounded,
    SupportTopicIcon.refund => Icons.currency_exchange_rounded,
    SupportTopicIcon.payment => Icons.payments_outlined,
    SupportTopicIcon.account => Icons.person_outline_rounded,
    SupportTopicIcon.safety => Icons.shield_outlined,
    SupportTopicIcon.delivery => Icons.inventory_2_outlined,
    SupportTopicIcon.help => Icons.help_outline_rounded,
  };

  static IconData issueIconOf(IssueIcon icon) => switch (icon) {
    IssueIcon.notMoving => Icons.pause_circle_outline_rounded,
    IssueIcon.unreachable => Icons.phone_disabled_outlined,
    IssueIcon.location => Icons.wrong_location_outlined,
    IssueIcon.payment => Icons.payments_outlined,
    IssueIcon.incomplete => Icons.unpublished_outlined,
    IssueIcon.package => Icons.inventory_2_outlined,
    IssueIcon.safety => Icons.shield_outlined,
    IssueIcon.account => Icons.person_outline_rounded,
    IssueIcon.receipt => Icons.receipt_long_outlined,
    IssueIcon.other => Icons.info_outline_rounded,
  };

  static String contextLabelOf(IssueContext context) => switch (context) {
    IssueContext.trip => 'A ride',
    IssueContext.delivery => 'A delivery',
    IssueContext.payment => 'A payment',
    IssueContext.account => 'My account',
  };

  static String statusLabelOf(TicketStatus status) => switch (status) {
    TicketStatus.reported => 'Received',
    TicketStatus.investigating => 'Looking into it',
    TicketStatus.actionNeeded => 'Your move',
    TicketStatus.resolved => 'Resolved',
    TicketStatus.closed => 'Closed',
  };

  static Widget statusTagOf(TicketStatus status) {
    final label = statusLabelOf(status);
    return switch (status) {
      TicketStatus.reported ||
      TicketStatus.investigating => SangaTag.scheduled(label: label, icon: Icons.schedule_rounded),
      TicketStatus.actionNeeded => SangaTag.urgent(label: label, icon: Icons.touch_app_outlined),
      TicketStatus.resolved || TicketStatus.closed => SangaTag.success(label: label),
    };
  }

  static String waitLine(SupportChat chat, SupportContact? contact) {
    final position = chat.queuePosition;
    final minutes = contact?.chatWaitMinutes ?? 0;
    final place = position <= 1 ? 'You’re next in line' : 'You’re number $position in line';
    return minutes > 0 ? '$place. About $minutes min wait.' : '$place.';
  }
}
