import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum AccountProblem {
  connection(CommonCopy.unreachableTryAgain),
  unknown(CommonCopy.serverTrouble),
  deleteUnconfirmed('We’re not sure the request went through. Check again before you try deleting.'),
  invalidEmail('That email doesn’t look right. Check it and try again.', code: ServerCode.invalidEmail),
  emailTaken('Another account already uses that email.', code: ServerCode.emailTaken),
  tooYoung('You need to be at least 16 to ride with Sanga.', code: ServerCode.tooYoung),
  nameRequired('Add your first and last name.', code: ServerCode.nameRequired),
  invalidPhone(CommonCopy.invalidPhoneSentence, code: ServerCode.invalidPhone),
  phoneTaken('This number already has an account.', code: ServerCode.phoneTaken),
  samePhone('That’s the number you already use.', code: ServerCode.samePhone),
  otpMismatch('That code didn’t match. Give it another go.', code: ServerCode.otpMismatch),
  otpExpired('That code has expired. Grab a new one.', code: ServerCode.otpExpired),
  photoUnreadable('We couldn’t read that photo. Try a different one.', code: ServerCode.photoUnreadable),
  photoTooLarge('That photo is too big. Try a smaller one.', code: ServerCode.fileTooLarge),
  cameraDenied('Camera is switched off. Allow it in Settings to take a photo.'),
  photosDenied('Photos are switched off. Allow them in Settings to pick one.'),
  activeTrip(
    'You have a trip in progress. Finish it first, then you can delete your account.',
    code: ServerCode.activeTrip,
  );

  const AccountProblem(this.message, {this.code});

  final String message;
  final String? code;

  bool get opensSettings => this == cameraDenied || this == photosDenied;

  static AccountProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => fromCode(code),
    _ => unknown,
  };

  static AccountProblem fromCode(String? code) =>
      codedEnum(values.where((problem) => problem.code != null), (problem) => problem.code!, code, orElse: unknown);
}
