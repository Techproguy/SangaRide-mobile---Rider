import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum LoadProblem {
  connection(SangaCommonCopy.connectionAnotherGo),
  unknown(SangaCommonCopy.serverTrouble);

  const LoadProblem(this.message);

  final String message;

  static LoadProblem of(Object error) => ProblemKind.of(error) is ProblemOffline ? connection : unknown;
}
