import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:sanga_ride/core/services/image_compression_service.dart';
import 'package:sanga_ride/model/models.dart';

abstract final class DocumentFileService {
  static const int maxPdfBytes = 5 * 1024 * 1024;
  static const String _pdf = 'pdf';
  static const List<String> _imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'];
  static const List<String> _allowedExtensions = [_pdf, ..._imageExtensions];

  static bool isPdf(String? path) => _extensionOf(path) == _pdf;

  static Future<String?> pick({required VoidCallback onPicked}) async {
    final path = await _pickPath();
    if (path == null) return null;
    onPicked();
    final extension = _extensionOf(path);
    if (extension == _pdf) return _checkedPdf(path);
    if (!_imageExtensions.contains(extension)) {
      await ImageCompressionService.discard(path);
      throw const PhotoException(DeliveryFailure.unsupportedType);
    }
    try {
      return await ImageCompressionService.compress(path);
    } finally {
      await ImageCompressionService.discard(path);
    }
  }

  static Future<String?> _pickPath() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: _allowedExtensions);
      return file?.path;
    } on PlatformException {
      throw const PhotoException(DeliveryFailure.unreadablePhoto);
    }
  }

  static Future<String> _checkedPdf(String path) async {
    final file = File(path);
    if (!await file.exists()) throw const PhotoException(DeliveryFailure.unreadablePhoto);
    if (await file.length() > maxPdfBytes) {
      await ImageCompressionService.discard(path);
      throw const PhotoException(DeliveryFailure.fileTooLarge);
    }
    return path;
  }

  static String _extensionOf(String? path) {
    final name = path?.split(Platform.pathSeparator).last ?? '';
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }
}
