import 'package:sanga_ride_core/sanga_ride_core.dart';

enum AuthProblem {
  offline,
  server,
  unknown;

  static AuthProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => offline,
    ProblemServer() => server,
    _ => unknown,
  };
}
