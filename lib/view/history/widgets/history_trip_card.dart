import 'package:flutter/material.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/view/history/widgets/history_timeline.dart';
import 'package:sanga_ride/view/history/widgets/rebook_button.dart';
import 'package:sanga_ride/view/ride/matching/widgets/driver_photo.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryTripCard extends StatelessWidget {
  const HistoryTripCard({super.key, required this.detail, this.onRebook});

  final HistoryDetail detail;
  final VoidCallback? onRebook;

  @override
  Widget build(BuildContext context) {
    final route = detail.route;
    return SangaListGroup(
      children: [
        Padding(padding: const EdgeInsets.all(SangaSpacing.md), child: _header()),
        Padding(
          padding: const EdgeInsets.all(SangaSpacing.md),
          child: SangaRouteSummary(
            pickup: route.pickup.name,
            stops: [for (final stop in route.stops) stop.name],
            dropoff: route.dropoff.name,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(SangaSpacing.md, SangaSpacing.md, SangaSpacing.md, 0),
          child: SangaTimeline(entries: historyTimelineEntries(context, detail.events)),
        ),
      ],
    );
  }

  Widget _header() {
    final driver = detail.driver?.profile;
    final rebook = onRebook == null ? null : RebookButton(onPressed: onRebook!);
    if (driver == null) {
      return Row(
        spacing: SangaSpacing.sm,
        children: [
          const SangaIconBadge(size: 40, child: Icon(Icons.person_off_outlined)),
          const Expanded(child: Text('No driver was assigned', style: SangaTextStyles.cardTitle)),
          ?rebook,
        ],
      );
    }
    return SangaPersonHeader(
      name: driver.name,
      rating: driver.rating,
      photo: driver.photo,
      isVerified: driver.isVerified,
      caption: driver.ridesLabel,
      trailing: rebook,
    );
  }
}
