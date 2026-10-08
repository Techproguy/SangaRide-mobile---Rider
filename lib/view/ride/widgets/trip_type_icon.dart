import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';

extension TripTypeIcon on TripType {
  IconData get icon => switch (this) {
    TripType.oneWay => Icons.arrow_upward_rounded,
    TripType.roundTrip => Icons.swap_vert_rounded,
    TripType.hourly => Icons.schedule_rounded,
    TripType.intercity => Icons.alt_route_rounded,
  };
}
