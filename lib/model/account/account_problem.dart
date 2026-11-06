import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum AccountProblem {
  connection(SangaCommonCopy.unreachableTryAgain),
  unknown(SangaCommonCopy.serverTrouble),
  conflict(SangaCommonCopy.conflictTryAgain),
  deleteUnconfirmed('We’re not sure the request went through. Check again before you try deleting.'),
  invalidEmail('That email doesn’t look right. Check it and try again.', code: ServerCode.invalidEmail),
  emailTaken('Another account already uses that email.', code: ServerCode.emailTaken),
  tooYoung('', code: ServerCode.tooYoung),
  nameRequired('Add your first and last name.', code: ServerCode.nameRequired),
  invalidPhone(CommonCopy.invalidPhoneSentence, code: ServerCode.invalidPhone),
  phoneTaken('This number already has an account.', code: ServerCode.phoneTaken),
  samePhone('That’s the number you already use.', code: ServerCode.samePhone),
  otpMismatch('That code didn’t match. Give it another go.', code: ServerCode.otpMismatch),
  otpExpired('That code has expired. Tap Resend to get a new one.', code: ServerCode.otpExpired),
  photoUnreadable('We couldn’t read that photo. Try a different one.', code: ServerCode.photoUnreadable),
  photoTooLarge('That photo is too big. Try a smaller one.', code: ServerCode.fileTooLarge),
  cameraDenied('Camera is switched off. Allow it in Settings to take a photo.'),
  photosDenied('Photos are switched off. Allow them in Settings to pick one.'),
  noCamera('There’s no camera on this phone. Choose a photo from your gallery instead.'),
  activeTrip(
    'You have a trip in progress. Finish it first, then you can delete your account.',
    code: ServerCode.activeTrip,
  );

  const AccountProblem(this._message, {this.code});

  final String _message;
  final String? code;

  String get message => this == tooYoung
      ? 'You need to be at least ${ServerConfig.current.minimumRiderAge} to ride with Sanga.'
      : _message;

  bool get opensSettings => this == cameraDenied || this == photosDenied;

  static AccountProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => _rejectedBy(error, code),
    _ => unknown,
  };

  static AccountProblem? conflictOf(Object error) {
    if (error is! ApiException || error.statusCode != 409) return null;
    return of(error);
  }

  static AccountProblem _rejectedBy(Object error, String? code) {
    final coded = fromCode(code);
    if (coded != unknown) return coded;
    if (error is! ApiException || error.statusCode != 409) return unknown;
    final message = error.message.toLowerCase();
    if (message.contains('email')) return emailTaken;
    if (message.contains('phone')) return phoneTaken;
    return conflict;
  }

  static AccountProblem fromCode(String? code) => switch (code) {
    ServerCode.otpInvalid => otpMismatch,
    ServerCode.emailAlreadyExists => emailTaken,
    ServerCode.phoneAlreadyExists => phoneTaken,
    _ => codedEnum(values.where((problem) => problem.code != null), (problem) => problem.code!, code, orElse: unknown),
  };
}
