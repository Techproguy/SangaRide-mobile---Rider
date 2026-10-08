enum SupportProblem {
  connection('We couldn’t reach the server. Check your connection and try again.'),
  articleNotFound('We couldn’t find that article. It may have moved.'),
  ticketNotFound('We couldn’t find that report.'),
  typeRequired('Pick what happened so we know how to help.'),
  noteTooLong('That note is a bit long. Keep it under 500 characters.'),
  invalidOption('That option isn’t available anymore. Pick another one.'),
  chatEnded('This chat has ended.'),
  chatUnavailable('Live chat isn’t available right now. You can call us or report an issue.');

  const SupportProblem(this.message);

  final String message;

  static SupportProblem fromCode(String? code) => switch (code) {
    'article_not_found' => articleNotFound,
    'ticket_not_found' => ticketNotFound,
    'type_required' => typeRequired,
    'note_too_long' => noteTooLong,
    'invalid_option' => invalidOption,
    'chat_ended' => chatEnded,
    'chat_unavailable' => chatUnavailable,
    _ => connection,
  };
}
