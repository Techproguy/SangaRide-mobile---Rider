import 'package:sanga_ride_core/sanga_ride_core.dart';

enum LoadProblem {
  connection('Check your connection and give it another go.'),
  unknown('Something went wrong on our side. Try again in a moment.');

  const LoadProblem(this.message);

  final String message;

  static LoadProblem of(Object error) => ProblemKind.of(error) is ProblemOffline ? connection : unknown;
}
