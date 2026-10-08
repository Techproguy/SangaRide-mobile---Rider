import 'package:flutter/material.dart';
import 'package:sanga_ride/core/format/time_format.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class IssueTimeline extends StatelessWidget {
  const IssueTimeline({super.key, required this.events, required this.status});

  final List<TicketEvent> events;
  final TicketStatus status;

  static String _titleOf(TicketEventType type) => switch (type) {
    TicketEventType.reported => 'Report received',
    TicketEventType.investigating => 'We’re on it',
    TicketEventType.actionRequested => 'Over to you',
    TicketEventType.actionTaken => 'You chose',
    TicketEventType.resolved => 'Resolved',
  };

  static IconData _iconOf(TicketEventType type) => switch (type) {
    TicketEventType.reported => Icons.flag_outlined,
    TicketEventType.investigating => Icons.search_rounded,
    TicketEventType.actionRequested => Icons.touch_app_outlined,
    TicketEventType.actionTaken => Icons.check_rounded,
    TicketEventType.resolved => Icons.verified_outlined,
  };

  SangaTimelineState _stateOf(TicketEvent event, bool isLast) {
    if (event.type == TicketEventType.actionRequested && isLast && status == TicketStatus.actionNeeded) {
      return SangaTimelineState.current;
    }
    return SangaTimelineState.done;
  }

  List<SangaTimelineEntry> _entries() {
    return [
      for (final (index, event) in events.indexed)
        SangaTimelineEntry.step(
          title: _titleOf(event.type),
          icon: _iconOf(event.type),
          state: _stateOf(event, index == events.length - 1),
          time: event.at == null ? null : TimeFormat.ago(event.at!),
          detail: event.detail.isEmpty ? null : event.detail,
        ),
      if (status.isWaiting)
        const SangaTimelineEntry.step(
          title: 'Resolution',
          icon: Icons.verified_outlined,
          state: SangaTimelineState.pending,
          detail: 'We’ll update you here',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SangaTimeline(
      entries: _entries(),
      isAccented: status == TicketStatus.resolved || status == TicketStatus.closed,
    );
  }
}
