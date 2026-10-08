enum DeliveryPickupProblem {
  cameraDenied(
    'camera_denied',
    'Camera is switched off',
    'Let Sanga use your camera in Settings to snap the package.',
    opensSettings: true,
    isPhotoProblem: true,
  ),
  cameraUnavailable(
    'camera_unavailable',
    'We can’t reach your camera',
    'Give it another go in a moment.',
    isPhotoProblem: true,
  ),
  unreadablePhoto(
    'unreadable_photo',
    'We couldn’t read that photo',
    'Snap it again and we’ll take it from there.',
    isPhotoProblem: true,
  ),
  fileTooLarge(
    'file_too_large',
    'That photo is too big',
    'Snap it again. Photos need to be under 8 MB.',
    isPhotoProblem: true,
  ),
  unsupportedType(
    'unsupported_type',
    'We can’t use that photo',
    'Snap it again with your camera.',
    isPhotoProblem: true,
  ),
  uploadFailed(
    'upload_failed',
    'We couldn’t upload your photo',
    'Check your connection and give it another go.',
    isPhotoProblem: true,
  ),
  movedOn(
    'wrong_stage',
    'This pickup has moved on',
    'Your driver has already carried on with the delivery.',
    isPhotoProblem: false,
  ),
  connection(
    'connection',
    'We couldn’t reach the server',
    'Check your connection and give it another go.',
    isPhotoProblem: false,
  );

  const DeliveryPickupProblem(
    this.code,
    this.title,
    this.message, {
    required this.isPhotoProblem,
    this.opensSettings = false,
  });

  final String code;
  final String title;
  final String message;
  final bool isPhotoProblem;
  final bool opensSettings;

  static DeliveryPickupProblem fromCode(String? code) =>
      values.firstWhere((problem) => problem.code == code, orElse: () => connection);
}

sealed class DeliveryPickupState {
  const DeliveryPickupState();

  String? get photoPath => null;

  bool get isBusy => false;

  bool get canConfirm => false;
}

final class PickupEmpty extends DeliveryPickupState {
  const PickupEmpty();

  @override
  bool get canConfirm => true;
}

final class PickupPreparing extends DeliveryPickupState {
  const PickupPreparing();

  @override
  bool get isBusy => true;
}

final class PickupUploading extends DeliveryPickupState {
  const PickupUploading(this.path, {required this.progress});

  final String path;
  final double progress;

  @override
  String? get photoPath => path;

  @override
  bool get isBusy => true;
}

final class PickupReady extends DeliveryPickupState {
  const PickupReady(this.path, {required this.photoId});

  final String path;
  final String photoId;

  @override
  String? get photoPath => path;

  @override
  bool get canConfirm => true;
}

final class PickupPhotoFailed extends DeliveryPickupState {
  const PickupPhotoFailed(this.problem, {this.path});

  final DeliveryPickupProblem problem;
  final String? path;

  @override
  String? get photoPath => path;

  @override
  bool get canConfirm => path == null;
}

final class PickupConfirming extends DeliveryPickupState {
  const PickupConfirming(this.path, {required this.photoId});

  final String? path;
  final String? photoId;

  @override
  String? get photoPath => path;

  @override
  bool get isBusy => true;
}

final class PickupConfirmFailed extends DeliveryPickupState {
  const PickupConfirmFailed(this.problem, {required this.path, required this.photoId});

  final DeliveryPickupProblem problem;
  final String? path;
  final String? photoId;

  @override
  String? get photoPath => path;

  @override
  bool get canConfirm => true;
}

final class PickupConfirmed extends DeliveryPickupState {
  const PickupConfirmed(this.path);

  final String? path;

  @override
  String? get photoPath => path;
}
