import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class DeliveryTimelineEntries {
  static const Map<DeliveryEventType, IconData> _icons = {
    DeliveryEventType.accepted: Icons.directions_car_rounded,
    DeliveryEventType.arrivedPickup: Icons.location_on_rounded,
    DeliveryEventType.pickedUp: Icons.inventory_2_rounded,
    DeliveryEventType.arrivedDropoff: Icons.location_on_rounded,
    DeliveryEventType.handedOver: Icons.how_to_reg_rounded,
    DeliveryEventType.delivered: Icons.check_rounded,
  };

  static List<SangaTimelineEntry> of(TripDelivery delivery) {
    final done = [
      for (final type in DeliveryEventType.values)
        if (delivery.hasEvent(type)) type,
    ];
    final ending = _endingOf(delivery);
    final remaining = [
      for (final type in DeliveryEventType.values)
        if (!done.contains(type)) type,
    ];
    return [
      for (final type in done)
        SangaTimelineEntry.step(
          title: type.label,
          state: SangaTimelineState.done,
          icon: _icons[type]!,
          time: _clock(delivery.eventTime(type)),
        ),
      if (ending != null)
        ending
      else
        for (final (index, type) in remaining.indexed)
          SangaTimelineEntry.step(
            title: type.label,
            state: index == 0 ? SangaTimelineState.current : SangaTimelineState.pending,
            icon: _icons[type]!,
          ),
    ];
  }

  static SangaTimelineEntry? _endingOf(TripDelivery delivery) {
    final refusal = delivery.refusal;
    return switch (delivery.stage) {
      DeliveryStage.refused => SangaTimelineEntry.step(
        title: 'Package not accepted',
        state: SangaTimelineState.alert,
        icon: Icons.block_rounded,
        time: _clock(refusal?.at),
      ),
      DeliveryStage.failed => const SangaTimelineEntry.step(
        title: 'Delivery couldn’t be completed',
        state: SangaTimelineState.alert,
        icon: Icons.close_rounded,
      ),
      _ => null,
    };
  }

  static String? _clock(DateTime? at) => at == null ? null : DateFormat('h:mm a').format(at);
}
