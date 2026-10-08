import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sanga_ride/core/api/mock/mock_capture.dart';
import 'package:sanga_ride/core/services/image_compression_service.dart';
import 'package:sanga_ride/model/models.dart';

abstract final class PackagePhotoService {
  static const double _pickerSide = 2400;
  static const Map<String, DeliveryFailure> _deniedCodes = {
    'camera_access_denied': DeliveryFailure.cameraDenied,
    'photo_access_denied': DeliveryFailure.photosDenied,
  };

  static Future<String?> pick(PhotoSource source, {required VoidCallback onPicked}) async {
    final original = await _pickOriginal(source);
    if (original == null) return null;
    onPicked();
    try {
      return await ImageCompressionService.compress(original);
    } finally {
      if (source == PhotoSource.camera) await ImageCompressionService.discard(original);
    }
  }

  static Future<String?> _pickOriginal(PhotoSource source) async {
    try {
      final photo = await ImagePicker().pickImage(
        source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: _pickerSide,
        maxHeight: _pickerSide,
        imageQuality: 92,
        preferredCameraDevice: CameraDevice.rear,
      );
      return photo?.path;
    } on PlatformException catch (error) {
      final denied = _deniedCodes[error.code];
      if (denied != null) throw PhotoException(denied);
      if (kDebugMode && source == PhotoSource.camera) return MockCapture.photo('Package');
      throw PhotoException(
        source == PhotoSource.camera ? DeliveryFailure.cameraUnavailable : DeliveryFailure.unreadablePhoto,
      );
    }
  }
}
