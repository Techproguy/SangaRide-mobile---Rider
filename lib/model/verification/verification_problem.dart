import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/delivery/delivery_failure.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum VerificationProblem {
  connection(CommonCopy.unreachableTryAgain),
  unknown(CommonCopy.serverTrouble),
  unconfirmed('We’re not sure that went through. Check the status before you send it again.'),
  incomplete('A few things still need your attention before we can review.', code: ServerCode.incomplete),
  uploadFailed('The upload didn’t go through. Check your connection and try again.', code: ServerCode.uploadFailed),
  fileTooLarge('That photo is over 5MB. Try a smaller one.', code: ServerCode.fileTooLarge),
  unsupportedType('We can’t use that file. Choose a JPG or PNG photo.', code: ServerCode.unsupportedType),
  unreadable('We couldn’t read that photo. Try another one or snap it again.'),
  cameraDenied('Camera is switched off. Allow it in Settings to take a photo.', opensSettings: true),
  photosDenied('Photos are switched off. Allow them in Settings to pick one.', opensSettings: true),
  cameraUnavailable('We can’t reach your camera. Try again, or choose a photo from your gallery.');

  const VerificationProblem(this.message, {this.opensSettings = false, this.code});

  final String message;
  final bool opensSettings;
  final String? code;

  static VerificationProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => fromCode(code),
    _ => unknown,
  };

  static VerificationProblem fromCode(String? code) =>
      codedEnum(values.where((problem) => problem.code != null), (problem) => problem.code!, code, orElse: unknown);

  static VerificationProblem fromPhoto(DeliveryFailure failure) => switch (failure) {
    DeliveryFailure.fileTooLarge => fileTooLarge,
    DeliveryFailure.unsupportedType => unsupportedType,
    DeliveryFailure.cameraDenied => cameraDenied,
    DeliveryFailure.photosDenied => photosDenied,
    DeliveryFailure.cameraUnavailable => cameraUnavailable,
    DeliveryFailure.connection => uploadFailed,
    _ => unreadable,
  };
}
