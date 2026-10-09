import 'package:sanga_ride_core/sanga_ride_core.dart';

enum AccountProblem {
  connection('We couldn’t reach the server. Check your connection and try again.'),
  unknown('Something went wrong on our side. Try again in a moment.'),
  deleteUnconfirmed('We’re not sure the request went through. Check again before you try deleting.'),
  invalidEmail('That email doesn’t look right. Check it and try again.'),
  emailTaken('Another account already uses that email.'),
  tooYoung('You need to be at least 16 to ride with Sanga.'),
  nameRequired('Add your first and last name.'),
  invalidPhone('Enter a valid Nigerian phone number.'),
  phoneTaken('This number already has an account.'),
  samePhone('That’s the number you already use.'),
  otpMismatch('That code didn’t match. Give it another go.'),
  otpExpired('That code has expired. Grab a new one.'),
  photoUnreadable('We couldn’t read that photo. Try a different one.'),
  photoTooLarge('That photo is too big. Try a smaller one.'),
  cameraDenied('Camera is switched off. Allow it in Settings to take a photo.'),
  photosDenied('Photos are switched off. Allow them in Settings to pick one.'),
  activeTrip('You have a trip in progress. Finish it first, then you can delete your account.');

  const AccountProblem(this.message);

  final String message;

  bool get opensSettings => this == cameraDenied || this == photosDenied;

  static AccountProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => fromCode(code),
    _ => unknown,
  };

  static AccountProblem fromCode(String? code) => switch (code) {
    'invalid_email' => invalidEmail,
    'email_taken' => emailTaken,
    'too_young' => tooYoung,
    'name_required' => nameRequired,
    'invalid_phone' => invalidPhone,
    'phone_taken' => phoneTaken,
    'same_phone' => samePhone,
    'otp_mismatch' => otpMismatch,
    'otp_expired' => otpExpired,
    'photo_unreadable' => photoUnreadable,
    'file_too_large' => photoTooLarge,
    'active_trip' => activeTrip,
    _ => unknown,
  };
}
