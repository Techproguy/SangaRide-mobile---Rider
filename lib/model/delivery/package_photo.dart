import 'package:sanga_ride/model/delivery/delivery_failure.dart';

enum PhotoSource { camera, gallery }

class PhotoException implements Exception {
  const PhotoException(this.failure);

  final DeliveryFailure failure;
}

sealed class PackagePhotoState {
  const PackagePhotoState();

  String? get localPath => null;

  String? get uploadId => null;

  bool get isBusy => false;
}

final class PhotoNone extends PackagePhotoState {
  const PhotoNone();
}

final class PhotoPreparing extends PackagePhotoState {
  const PhotoPreparing();

  @override
  bool get isBusy => true;
}

final class PhotoUploading extends PackagePhotoState {
  const PhotoUploading({required this.path, required this.progress});

  final String path;
  final double progress;

  @override
  String get localPath => path;

  @override
  bool get isBusy => true;
}

final class PhotoUploaded extends PackagePhotoState {
  const PhotoUploaded({required this.path, required this.id, required this.url});

  final String path;
  final String id;
  final String url;

  @override
  String get localPath => path;

  @override
  String get uploadId => id;
}

final class PhotoFailed extends PackagePhotoState {
  const PhotoFailed({required this.failure, this.path});

  final DeliveryFailure failure;
  final String? path;

  @override
  String? get localPath => path;
}
