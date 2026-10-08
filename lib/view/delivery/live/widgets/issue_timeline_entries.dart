import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class IssueTimelineEntries {
  static const String waitingForChoice = 'Waiting for your choice';

  static List<SangaTimelineEntry> of(DeliveryIssue issue) {
    const types = DeliveryIssueEventType.values;
    final firstPending = issue.status.isOpen ? types.indexWhere((type) => issue.eventOf(type)?.at == null) : -1;
    return [for (final (index, type) in types.indexed) _entry(issue, type, isCurrent: index == firstPending)];
  }

  static SangaTimelineEntry _entry(DeliveryIssue issue, DeliveryIssueEventType type, {required bool isCurrent}) {
    final event = issue.eventOf(type);
    final at = event?.at;
    final isDone = at != null;
    final isWaitingForChoice =
        type == DeliveryIssueEventType.resolved && issue.status == DeliveryIssueStatus.actionNeeded;
    return SangaTimelineEntry.step(
      title: isWaitingForChoice ? waitingForChoice : type.title,
      state: isDone
          ? SangaTimelineState.done
          : isCurrent
          ? SangaTimelineState.current
          : SangaTimelineState.pending,
      icon: _icons[type]!,
      time: at == null ? null : DateFormat('h:mm a').format(at),
      detail: isDone || isCurrent ? event?.detail : null,
    );
  }

  static const Map<DeliveryIssueEventType, IconData> _icons = {
    DeliveryIssueEventType.reported: Icons.check_rounded,
    DeliveryIssueEventType.investigating: Icons.search_rounded,
    DeliveryIssueEventType.actionTaken: Icons.bolt_rounded,
    DeliveryIssueEventType.resolved: Icons.check_rounded,
  };
}
