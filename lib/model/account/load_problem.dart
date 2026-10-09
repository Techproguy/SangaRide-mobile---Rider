import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum LoadProblem {
  connection(CommonCopy.connectionBody),
  unknown(CommonCopy.serverTrouble);

  const LoadProblem(this.message);

  final String message;

  static LoadProblem of(Object error) => ProblemKind.of(error) is ProblemOffline ? connection : unknown;
}
