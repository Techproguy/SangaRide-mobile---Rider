import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

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
    ServerCode.fileTooLarge,
    'That photo is too big',
    'Snap it again. Photos need to be under 8 MB.',
    isPhotoProblem: true,
  ),
  unsupportedType(
    ServerCode.unsupportedType,
    'We can’t use that photo',
    'Snap it again with your camera.',
    isPhotoProblem: true,
  ),
  uploadFailed(
    ServerCode.uploadFailed,
    'We couldn’t upload your photo',
    CommonCopy.connectionBody,
    isPhotoProblem: true,
  ),
  movedOn(
    ServerCode.wrongStage,
    'This pickup has moved on',
    'Your driver has already carried on with the delivery.',
    isPhotoProblem: false,
  ),
  connection('connection', CommonCopy.unreachableTitle, CommonCopy.connectionBody, isPhotoProblem: false),
  unknown('unknown', CommonCopy.serverTitle, CommonCopy.serverTrouble, isPhotoProblem: false);

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

  static DeliveryPickupProblem fromCode(String? code) => enumByCode(values, code, (problem) => problem.code, unknown);

  static DeliveryPickupProblem of(Object error) {
    if (error is ApiException && error.kind == ApiFailureKind.rejected) return fromCode(error.code);
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => connection,
      _ => unknown,
    };
  }
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
