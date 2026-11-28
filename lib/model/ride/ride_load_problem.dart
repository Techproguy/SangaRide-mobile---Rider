import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class IntercityCopy {
  static const String unavailable = 'We can’t do that intercity route yet.';
  static const String sameCity = 'Pick a drop off in a different city.';
}

enum RideLoadProblem {
  connection('You’re offline. Check your connection and try again.'),
  outsideServiceArea('We don’t cover that area yet. Pick a pickup and drop off inside our service area.'),
  intercityUnavailable(IntercityCopy.unavailable),
  sameCity(IntercityCopy.sameCity),
  unknown(SangaCommonCopy.serverTrouble);

  const RideLoadProblem(this.message);

  final String message;

  static RideLoadProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => switch (code) {
      'outside_service_area' => outsideServiceArea,
      'intercity_unavailable' => intercityUnavailable,
      'same_city' => sameCity,
      _ => unknown,
    },
    _ => unknown,
  };
}
