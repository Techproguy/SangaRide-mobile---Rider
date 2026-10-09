import 'package:sanga_ride_core/sanga_ride_core.dart';

enum SupportProblem {
  connection('We couldn’t reach the server. Check your connection and try again.'),
  unknown('Something went wrong on our side. Try again in a moment.'),
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
    'article_not_found' => articleNotFound,
    'ticket_not_found' => ticketNotFound,
    'type_required' => typeRequired,
    'note_too_long' => noteTooLong,
    'invalid_option' => invalidOption,
    'chat_ended' => chatEnded,
    'chat_unavailable' => chatUnavailable,
    _ => unknown,
  };
}
