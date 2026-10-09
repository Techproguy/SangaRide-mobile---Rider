import 'package:sanga_ride_core/sanga_ride_core.dart';

enum RideLoadProblem {
  connection('You’re offline. Check your connection and try again.'),
  unknown('Something went wrong on our side. Try again in a moment.');

  const RideLoadProblem(this.message);

  final String message;

  static RideLoadProblem of(Object error) => ProblemKind.of(error) is ProblemOffline ? connection : unknown;
}
