import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum SupportProblem {
  connection(CommonCopy.unreachableTryAgain),
  unknown(CommonCopy.serverTrouble),
  unconfirmed('We’re not sure that went through. Check before you send it again.'),
  articleNotFound('We couldn’t find that article. It may have moved.'),
  ticketNotFound('We couldn’t find that report.'),
  typeRequired('Pick what happened so we know how to help.'),
  noteTooLong('That note is a bit long. Keep it under 500 characters.'),
  invalidOption('That option isn’t available anymore. Pick another one.'),
  chatEnded('This chat has ended.'),
  chatUnavailable('Live chat isn’t available right now. You can call us or report an issue.');

  const SupportProblem(this.message);

  final String message;

  static SupportProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => fromCode(code),
    _ => unknown,
  };

  static SupportProblem fromCode(String? code) => switch (code) {
    ServerCode.articleNotFound => articleNotFound,
    ServerCode.ticketNotFound => ticketNotFound,
    ServerCode.typeRequired => typeRequired,
    ServerCode.noteTooLong => noteTooLong,
    ServerCode.invalidOption => invalidOption,
    ServerCode.chatEnded => chatEnded,
    ServerCode.chatUnavailable => chatUnavailable,
    _ => unknown,
  };
}
