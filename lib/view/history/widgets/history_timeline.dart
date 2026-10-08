import 'package:flutter/widgets.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_schedule_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

List<SangaTimelineEntry> historyTimelineEntries(BuildContext context, List<HistoryEvent> events) {
  return [
    for (final event in events)
      SangaTimelineEntry.step(
        title: event.type.label,
        icon: event.type.icon,
        time: formatRideClock(context, event.at),
        state: event.type.isCancellation ? SangaTimelineState.alert : SangaTimelineState.done,
      ),
  ];
}
