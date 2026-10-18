import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RoutePanel extends StatelessWidget {
  const RoutePanel({
    super.key,
    required this.pickup,
    required this.stops,
    required this.dropoff,
    required this.canAddStop,
    required this.onEdit,
    required this.onRemoveStop,
    required this.onConfirm,
  });

  final Place? pickup;
  final List<Place> stops;
  final Place? dropoff;
  final bool canAddStop;
  final ValueChanged<RouteEdit> onEdit;
  final ValueChanged<int> onRemoveStop;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return SangaMapPanel(
      children: [
        SangaLocationRow(
          kind: SangaStopKind.pickup,
          title: pickup?.title ?? 'Pickup location',
          subtitle: pickup?.subtitle ?? 'Choose your pick up point',
          isPlaceholder: pickup == null,
          onTap: () => onEdit(const RouteEdit.pickup()),
        ),
        for (final (index, stop) in stops.indexed) ...[
          const SizedBox(height: SangaSpacing.sm),
          SangaLocationRow(
            kind: SangaStopKind.stop,
            title: stop.title,
            subtitle: 'Stop ${index + 1} · ${stop.subtitle}',
            onTap: () => onEdit(RouteEdit.stop(index)),
            trailing: IconButton(
              tooltip: 'Remove stop',
              visualDensity: VisualDensity.compact,
              onPressed: () => onRemoveStop(index),
              icon: const SangaIcon(SangaAssets.close, size: 14),
            ),
          ),
        ],
        const SizedBox(height: SangaSpacing.sm),
        SangaLocationRow(
          kind: SangaStopKind.dropoff,
          title: dropoff?.title ?? 'Drop off location',
          subtitle: dropoff?.subtitle ?? 'Choose your drop off point',
          isPlaceholder: dropoff == null,
          onTap: () => onEdit(const RouteEdit.dropoff()),
        ),
        if (canAddStop) SangaTextLink(label: '+ Add a stop', onPressed: () => onEdit(const RouteEdit.stop())),
        const SizedBox(height: SangaSpacing.lg),
        SangaButton.primary(label: 'Confirm', onPressed: onConfirm),
      ],
    );
  }
}
