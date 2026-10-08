import 'package:sanga_ride/model/delivery/delivery_failure.dart';

enum VerificationProblem {
  connection('We couldn’t reach the server. Check your connection and try again.'),
  incomplete('A few things still need your attention before we can review.'),
  uploadFailed('The upload didn’t go through. Check your connection and try again.'),
  fileTooLarge('That photo is over 5MB. Try a smaller one.'),
  unsupportedType('We can’t use that file. Choose a JPG or PNG photo.'),
  unreadable('We couldn’t read that photo. Try another one or snap it again.'),
  cameraDenied('Camera is switched off. Allow it in Settings to take a photo.', opensSettings: true),
  photosDenied('Photos are switched off. Allow them in Settings to pick one.', opensSettings: true),
  cameraUnavailable('We can’t reach your camera. Try again, or choose a photo from your gallery.');

  const VerificationProblem(this.message, {this.opensSettings = false});

  final String message;
  final bool opensSettings;

  static VerificationProblem fromCode(String? code) => switch (code) {
    'incomplete' => incomplete,
    'upload_failed' => uploadFailed,
    'file_too_large' => fileTooLarge,
    'unsupported_type' => unsupportedType,
    _ => connection,
  };

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
