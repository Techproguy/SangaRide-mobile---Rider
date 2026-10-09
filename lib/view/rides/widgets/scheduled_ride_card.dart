import 'package:flutter/material.dart';
import 'package:sanga_ride/model/ride/scheduled_ride.dart';
import 'package:sanga_ride/view/ride/widgets/ride_option_image.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ScheduledRideCard extends StatelessWidget {
  const ScheduledRideCard({
    super.key,
    required this.ride,
    required this.whenLabel,
    required this.tagLabel,
    required this.onCancel,
    this.onTap,
    this.flightLabel,
    this.repeatLabel,
    this.reminderLabel,
    this.busyAction,
    this.onRemind,
  });

  final ScheduledRide ride;
  final String whenLabel;
  final String tagLabel;
  final String? repeatLabel;
  final String? reminderLabel;
  final ScheduledAction? busyAction;
  final VoidCallback onCancel;
  final VoidCallback? onTap;
  final String? flightLabel;
  final VoidCallback? onRemind;

  static const double _stackScale = 1.3;

  bool get _isBusy => busyAction != null;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: SangaRadii.field,
        boxShadow: [BoxShadow(color: SangaColors.cardShadow, blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Material(
        color: SangaColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: SangaRadii.field,
          side: BorderSide(color: SangaColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(SangaSpacing.md),
                child: IntrinsicHeight(
                  child: Row(
                    spacing: SangaSpacing.md,
                    children: [
                      _vehicle(),
                      const VerticalDivider(width: 1, thickness: 1, color: SangaColors.divider),
                      Expanded(child: _details(context)),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: SangaColors.cardBorder),
            Padding(padding: const EdgeInsets.all(SangaSpacing.sm), child: _actions()),
          ],
        ),
      ),
    );
  }

  Widget _vehicle() {
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: SangaSpacing.xs,
        children: [
          Image(image: ride.category.image, fit: BoxFit.contain),
          Text(SangaMoney.naira(ride.fare), style: SangaTextStyles.cardValue),
        ],
      ),
    );
  }

  Widget _details(BuildContext context) {
    final isStacked = MediaQuery.textScalerOf(context).scale(1) > _stackScale;
    final tag = SangaTag.scheduled(label: tagLabel, icon: ride.airport == null ? null : Icons.flight_land_rounded);
    final when = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.xxs,
      children: [
        Text(whenLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardTitle),
        if (repeatLabel != null) Text(repeatLabel!, style: SangaTextStyles.cardSubtitle),
        if (flightLabel != null) Text(flightLabel!, style: SangaTextStyles.cardSubtitle),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.sm,
      children: [
        if (isStacked)
          Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: SangaSpacing.xs, children: [when, tag])
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.xs,
            children: [
              Expanded(child: when),
              tag,
            ],
          ),
        _stop(SangaStopKind.pickup, ride.pickup),
        _stop(SangaStopKind.dropoff, ride.dropoff),
      ],
    );
  }

  Widget _stop(SangaStopKind kind, ScheduledStop stop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.xs,
      children: [
        SangaStopPin(kind, size: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardTitle),
              Text(stop.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.tileSubtitle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    return Row(
      spacing: SangaSpacing.sm,
      children: [
        if (onRemind != null)
          Expanded(
            child: SangaButton.outline(
              label: 'Remind me',
              size: SangaButtonSize.compact,
              isLoading: busyAction == ScheduledAction.remind,
              onPressed: _isBusy ? null : onRemind,
            ),
          )
        else if (reminderLabel != null)
          Expanded(
            child: Row(
              spacing: SangaSpacing.xs,
              children: [
                const Icon(Icons.notifications_active_outlined, size: 16, color: SangaColors.primary),
                Expanded(child: Text(reminderLabel!, style: SangaTextStyles.cardSubtitle)),
              ],
            ),
          )
        else
          const Spacer(),
        Expanded(
          child: SangaButton.outline(
            label: ride.isRepeat ? 'Cancel repeat' : 'Cancel ride',
            size: SangaButtonSize.compact,
            isLoading: busyAction == ScheduledAction.cancel,
            onPressed: _isBusy ? null : onCancel,
          ),
        ),
      ],
    );
  }
}
