import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/extensions/lat_lng.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_maps/sanga_ride_maps.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TripEtaLine extends StatelessWidget {
  const TripEtaLine({super.key, required this.etaAt, this.distanceRemainingKm});

  final DateTime? etaAt;
  final double? distanceRemainingKm;

  static String labelFor(Duration remaining) {
    if (remaining < const Duration(minutes: 1)) return 'Arriving now';
    final minutes = (remaining.inSeconds / 60).ceil();
    return minutes == 1 ? '1 minute away' : '$minutes minutes away';
  }

  @override
  Widget build(BuildContext context) {
    final etaAt = this.etaAt;
    if (etaAt == null) return const SizedBox.shrink();
    final distance = distanceRemainingKm;
    return SangaCountdown(
      endsAt: etaAt,
      builder: (context, remaining) {
        final label = distance == null || remaining < const Duration(minutes: 1)
            ? labelFor(remaining)
            : '${labelFor(remaining)} · ${SangaDistance.format(distance * 1000)}';
        return Text(
          label,
          textAlign: TextAlign.end,
          style: SangaTextStyles.cardTitle.copyWith(color: SangaColors.primary),
        );
      },
    );
  }
}

class DriverApproachEta extends StatefulWidget {
  const DriverApproachEta({super.key, required this.trip});

  final Trip trip;

  @override
  State<DriverApproachEta> createState() => _DriverApproachEtaState();
}

class _DriverApproachEtaState extends State<DriverApproachEta> {
  static const double _refetchMeters = 150;
  static const Duration _refetchAfter = Duration(seconds: 30);

  DateTime? _etaAt;
  double? _distanceKm;
  LatLng? _fetchedFrom;
  DateTime _fetchedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  @override
  void didUpdateWidget(DriverApproachEta oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_refresh());
  }

  bool get _isDue {
    final driver = widget.trip.driverPosition?.position;
    final from = _fetchedFrom;
    if (driver == null) return false;
    if (from == null) return true;
    return driver.metersTo(from) >= _refetchMeters || DateTime.now().difference(_fetchedAt) >= _refetchAfter;
  }

  Future<void> _refresh() async {
    final driver = widget.trip.driverPosition?.position;
    if (driver == null || !_isDue) return;
    _fetchedFrom = driver;
    _fetchedAt = DateTime.now();
    final route = await SangaRouteService.shared.route([driver, widget.trip.pickup.position]);
    final seconds = route.durationSeconds;
    if (!mounted || route.isEstimate || seconds == null) return;
    setState(() {
      _etaAt = DateTime.now().add(Duration(seconds: seconds));
      _distanceKm = route.distanceMeters / 1000;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return TripEtaLine(
      etaAt: trip.etaAt ?? _etaAt,
      distanceRemainingKm: trip.etaAt == null ? _distanceKm : trip.distanceRemainingKm,
    );
  }
}
