import 'package:flutter/material.dart';
import 'package:sanga_ride/model/ride/booking.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HourlyDurationOptions extends StatelessWidget {
  const HourlyDurationOptions({
    super.key,
    required this.catalog,
    required this.hourlyRate,
    required this.hours,
    required this.isCustom,
    required this.onPreset,
    required this.onCustom,
    required this.onHoursChanged,
  });

  final HourlyCatalog catalog;
  final num hourlyRate;
  final int hours;
  final bool isCustom;
  final ValueChanged<int> onPreset;
  final VoidCallback onCustom;
  final ValueChanged<int> onHoursChanged;

  static String hoursLabel(int hours) => hours == 1 ? '1 hour' : '$hours hours';

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.md,
      children: [
        for (final preset in catalog.presets)
          SangaOptionCard(
            leading: const SangaIconBadge(child: Icon(Icons.schedule_rounded)),
            title: hoursLabel(preset.hours),
            subtitle: preset.blurb,
            value: SangaMoney.naira(hourlyRate * preset.hours),
            isSelected: !isCustom && hours == preset.hours,
            onTap: () => onPreset(preset.hours),
          ),
        SangaOptionCard(
          leading: const SangaIconBadge(child: Icon(Icons.tune_rounded)),
          title: 'Custom duration',
          subtitle: 'Anything from ${catalog.minHours} to ${catalog.maxHours} hours',
          value: isCustom ? SangaMoney.naira(hourlyRate * hours) : null,
          isSelected: isCustom,
          onTap: onCustom,
        ),
        if (isCustom)
          Row(
            children: [
              Expanded(child: Text(hoursLabel(hours), style: SangaTextStyles.cardTitle)),
              SangaCounter(value: hours, min: catalog.minHours, max: catalog.maxHours, onChanged: onHoursChanged),
            ],
          ),
      ],
    );
  }
}
