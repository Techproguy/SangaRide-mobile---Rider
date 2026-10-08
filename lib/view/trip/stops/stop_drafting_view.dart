import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/stops/widgets/stops_route_card.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class StopDraftingView extends StatelessWidget {
  const StopDraftingView({
    super.key,
    required this.trip,
    required this.added,
    required this.slotsLeft,
    required this.onChoose,
    required this.onRemove,
    required this.onDone,
  });

  final Trip trip;
  final List<Place> added;
  final int slotsLeft;
  final VoidCallback onChoose;
  final ValueChanged<int> onRemove;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Add stops',
      footer: added.isEmpty ? null : SangaButton.primary(label: 'Done', onPressed: onDone),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.md,
          children: [
            StopsRouteCard(entries: StopsRouteEntry.of(trip, added, onRemove: onRemove)),
            if (slotsLeft > 0 && added.isEmpty)
              SangaLocationRow(
                kind: SangaStopKind.stop,
                title: 'Choose a stop',
                subtitle: 'Search for where you’d like to stop',
                isPlaceholder: true,
                onTap: onChoose,
              )
            else if (slotsLeft > 0)
              SangaButton.outline(label: '+ Add another stop', onPressed: onChoose)
            else if (added.isEmpty)
              const SangaNotice(
                message: 'This trip already has all the stops it can hold.',
                tone: SangaTone.neutral,
                icon: Icons.info_outline_rounded,
              ),
          ],
        ),
      ],
    );
  }
}
