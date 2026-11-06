import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum RideLoadProblem {
  connection('You’re offline. Check your connection and try again.'),
  unknown(SangaCommonCopy.serverTrouble);

  const RideLoadProblem(this.message);

  final String message;

  static RideLoadProblem of(Object error) => ProblemKind.of(error) is ProblemOffline ? connection : unknown;
}
