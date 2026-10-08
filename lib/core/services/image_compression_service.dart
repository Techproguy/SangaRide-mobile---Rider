import 'dart:developer';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:sanga_ride/model/models.dart';

abstract final class ImageCompressionService {
  static const int _longestSide = 1600;
  static const int _targetBytes = 1536 * 1024;
  static const List<int> _qualitySteps = [82, 70, 58, 45];

  static Future<String> compress(String path) async {
    if (!await File(path).exists()) throw const PhotoException(DeliveryFailure.unreadablePhoto);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final attempts = <File>[];
    for (final (index, quality) in _qualitySteps.indexed) {
      final output = await _compressOnce(
        path,
        '${Directory.systemTemp.path}/sanga_package_${stamp}_$index.jpg',
        quality,
      );
      attempts.add(output);
      if (await output.length() <= _targetBytes) return _keepOnly(output, attempts);
    }
    final best = attempts.last;
    if (await best.length() > DeliveryRules.maxPhotoBytes) {
      await _keepOnly(null, attempts);
      throw const PhotoException(DeliveryFailure.fileTooLarge);
    }
    return _keepOnly(best, attempts);
  }

  static Future<void> discard(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (error) {
      log('photo cleanup failed: $error');
    }
  }

  static Future<File> _compressOnce(String path, String target, int quality) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        target,
        quality: quality,
        minWidth: _longestSide,
        minHeight: _longestSide,
        format: CompressFormat.jpeg,
      );
      if (result == null) throw const PhotoException(DeliveryFailure.unreadablePhoto);
      return File(result.path);
    } on PhotoException {
      rethrow;
    } on Object catch (error) {
      log('photo compression failed: $error');
      throw const PhotoException(DeliveryFailure.unreadablePhoto);
    }
  }

  static Future<String> _keepOnly(File? keep, List<File> attempts) async {
    for (final attempt in attempts) {
      if (attempt.path != keep?.path) await discard(attempt.path);
    }
    return keep?.path ?? '';
  }
}
