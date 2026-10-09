import 'package:flutter/material.dart';
import 'package:sanga_ride/core/safety_config.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/router/safety_routes.dart';
import 'package:sanga_ride/core/router/trip_routes.dart';
import 'package:sanga_ride/core/services/me_state.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class LiveActivities {
  static const String tripId = 'trip';
  static const String sosId = 'sos';
  static const String requestId = 'request';

  static List<SangaLiveActivity> from(MeState? state, String path) {
    if (state == null) return const [];
    final trip = state.activeTrip;
    return [
      if (state.activeSosId != null && !path.startsWith(SafetyRoutes.centre))
        const SangaLiveActivity(
          id: sosId,
          tone: SangaLiveActivityTone.sos,
          icon: Icons.shield_outlined,
          title: 'SOS is active',
          subtitle: 'Tap to open your Safety Centre',
          actionLabel: 'Call ${SafetyConfig.emergencyNumber}',
          actionIcon: Icons.call_rounded,
        ),
      if (trip != null && path != TripRoutes.tripOf(trip.id))
        const SangaLiveActivity(
          id: tripId,
          tone: SangaLiveActivityTone.live,
          icon: Icons.directions_car_filled_rounded,
          title: 'Trip in progress',
          subtitle: 'Tap to return to your trip',
        ),
      if (state.activeRideRequest != null && !path.startsWith('/ride/'))
        const SangaLiveActivity(
          id: requestId,
          tone: SangaLiveActivityTone.info,
          icon: Icons.search_rounded,
          title: 'Finding your driver',
          subtitle: 'Tap to return to your request',
        ),
    ];
  }

  static String? routeFor(String id, MeState? state) {
    return switch (id) {
      sosId => SafetyRoutes.centreOf(tripId: state?.activeTrip?.id),
      tripId => state?.activeTrip == null ? null : TripRoutes.tripOf(state!.activeTrip!.id),
      requestId => SangaRoutes.rideOffers,
      _ => null,
    };
  }
}
