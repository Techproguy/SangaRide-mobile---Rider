import 'package:get_storage/get_storage.dart';
import 'package:sanga_ride/model/verification/id_document_type.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class UploadLimits {
  const UploadLimits({required this.maxBytes, required this.imageFormats, required this.documentFormats});

  static UploadLimits? tryFromReader(JsonReader? reader) {
    final maxBytes = reader?.intOrNull('maxBytes');
    if (reader == null || maxBytes == null || maxBytes <= 0) return null;
    return UploadLimits(
      maxBytes: maxBytes,
      imageFormats: reader.strings('imageFormats'),
      documentFormats: reader.strings('documentFormats'),
    );
  }

  static const Map<String, List<String>> _extensionsOf = {
    'image/jpeg': ['jpg', 'jpeg'],
    'image/png': ['png'],
    'image/webp': ['webp'],
    'image/heic': ['heic', 'heif'],
    'application/pdf': ['pdf'],
  };

  final int maxBytes;
  final List<String> imageFormats;
  final List<String> documentFormats;

  List<String> get imageExtensions => _extensionsFor(imageFormats);

  String get summary {
    final size = maxBytes >= 1048576 ? '${(maxBytes / 1048576).round()}MB' : '${(maxBytes / 1024).round()}KB';
    final kinds = documentFormats.map((format) => format.split('/').last.toUpperCase()).join(', ');
    return kinds.isEmpty ? 'Up to $size each' : 'Accepted formats: $kinds, up to $size each';
  }

  List<String> get documentExtensions => _extensionsFor(documentFormats);

  static List<String> _extensionsFor(List<String> mimeTypes) => [
    for (final mime in mimeTypes) ...?_extensionsOf[mime],
  ];
}

abstract final class RiderConfig {
  static const String _storageKey = 'rider_server_config';
  static const String _documentTypesKey = 'riderDocumentTypes';
  static const String _uploadsKey = 'uploads';

  static List<IdDocumentType> documentTypes = const [];
  static UploadLimits? uploads;

  static void restore() => _read(GetStorage().read<Object?>(_storageKey));

  static void apply(Object? data) {
    final received = JsonReader.of(data);
    if (!received.has(_documentTypesKey) && !received.has(_uploadsKey)) return;
    final stored = {
      _documentTypesKey: received.raw[_documentTypesKey],
      _uploadsKey: received.raw[_uploadsKey],
    };
    _read(stored);
    GetStorage().write(_storageKey, stored);
  }

  static IdDocumentType? documentTypeOf(String? code) =>
      documentTypes.where((type) => type.code == code).firstOrNull;

  static void _read(Object? data) {
    final reader = JsonReader.of(data);
    documentTypes = reader.listOf(_documentTypesKey, IdDocumentType.fromReader);
    uploads = UploadLimits.tryFromReader(reader.objectOrNull(_uploadsKey));
  }
}
