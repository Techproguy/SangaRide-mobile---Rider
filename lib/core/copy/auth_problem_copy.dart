import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride/model/auth/auth_problem.dart';

abstract final class AuthProblemCopy {
  static const String server = 'Something went wrong on our side. Try again in a moment.';
}

extension AuthProblemMessage on AuthProblem {
  String get message => switch (this) {
    AuthProblem.offline => SangaCommonCopy.offlineTryAgain,
    AuthProblem.server || AuthProblem.unknown => AuthProblemCopy.server,
  };
}
