import 'package:sanga_ride_core/sanga_ride_core.dart';

enum SafetyProblem {
  sosAlreadyActive('sos_already_active', 'You already have an SOS running.'),
  locationUnavailable('location_unavailable', 'We couldn’t find your location. We can still send your SOS without it.'),
  duplicateContact('duplicate_contact', 'That person is already one of your contacts.'),
  contactsLimit('contacts_limit', 'You’ve added the most contacts you can. Remove one to add another.'),
  invalidPhone('invalid_phone', 'Enter a valid Nigerian phone number.'),
  ownNumber('own_number', 'That’s your own number. Add someone else.'),
  detailsTooShort('details_too_short', 'Tell us a little more so we can help.'),
  connection('connection', 'We couldn’t reach the server. Check your connection and give it another go.'),
  unconfirmed('unconfirmed', 'We couldn’t confirm your SOS went out. Try again, or call for help right away.'),
  unknown('unknown', 'Something went wrong on our side. Try again in a moment.'),
  generic('generic', 'Something went wrong. Give it another go.');

  const SafetyProblem(this.code, this.message);

  final String code;
  final String message;

  bool get isPhoneProblem => this == duplicateContact || this == invalidPhone || this == ownNumber;

  static SafetyProblem fromCode(String? code) => enumByCode(values, code, (problem) => problem.code, unknown);

  static SafetyProblem of(Object error) {
    if (error is ApiException && error.kind == ApiFailureKind.rejected) return fromCode(error.code);
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => connection,
      _ => unknown,
    };
  }
}
