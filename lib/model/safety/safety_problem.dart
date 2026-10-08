enum SafetyProblem {
  sosAlreadyActive('sos_already_active', 'You already have an SOS running.'),
  locationUnavailable('location_unavailable', 'We couldn’t find your location. We can still send your SOS without it.'),
  duplicateContact('duplicate_contact', 'That person is already one of your contacts.'),
  contactsLimit('contacts_limit', 'You’ve added the most contacts you can. Remove one to add another.'),
  invalidPhone('invalid_phone', 'Enter a valid Nigerian phone number.'),
  ownNumber('own_number', 'That’s your own number. Add someone else.'),
  detailsTooShort('details_too_short', 'Tell us a little more so we can help.'),
  connection('connection', 'We couldn’t reach the server. Check your connection and give it another go.'),
  generic('generic', 'Something went wrong. Give it another go.');

  const SafetyProblem(this.code, this.message);

  final String code;
  final String message;

  bool get isPhoneProblem => this == duplicateContact || this == invalidPhone || this == ownNumber;

  static SafetyProblem fromCode(String? code) =>
      values.firstWhere((problem) => problem.code == code, orElse: () => generic);
}
