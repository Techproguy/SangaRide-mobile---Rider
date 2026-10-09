part of 'ride_request_controller.dart';

extension RideRequestRoute on RideRequestController {
  void setPickup(Place place) {
    _pickup.value = place;
    _clearQuote();
  }

  void setDropoff(Place place) {
    _dropoff.value = place;
    _clearQuote();
  }

  String? applyRouteEdit(RouteEdit edit, Place place) {
    final others = [
      if (edit.point != RoutePoint.pickup) pickup,
      for (final (index, stop) in stops.indexed)
        if (edit.point != RoutePoint.stop || edit.stopIndex != index) stop,
      if (edit.point != RoutePoint.dropoff) dropoff,
    ].whereType<Place>();
    final clash = others.where((other) => other.isSameAs(place)).firstOrNull;
    if (clash != null) {
      final isEnds = edit.point != RoutePoint.stop && (identical(clash, pickup) || identical(clash, dropoff));
      return isEnds ? 'Your pickup and drop off can’t be the same place.' : 'That place is already on your route.';
    }
    switch (edit.point) {
      case RoutePoint.pickup:
        setPickup(place);
      case RoutePoint.dropoff:
        setDropoff(place);
      case RoutePoint.stop:
        final index = edit.stopIndex;
        if (index == null) {
          const limit = RideRequestController.maxStops;
          if (stops.length >= limit) return 'You can add up to $limit stops.';
          _stops.add(place);
        } else {
          _stops[index] = place;
        }
        _clearQuote();
    }
    return null;
  }

  void removeStopAt(int index) {
    _stops.removeAt(index);
    _clearQuote();
  }
}
