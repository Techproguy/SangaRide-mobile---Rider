import 'package:flutter/foundation.dart';
import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/verification_endpoints.dart';

abstract final class MockVerification {
  static const String rejectedDocumentType = 'drivers_license';
  static const Duration _reviewTime = Duration(seconds: 20);
  static const int _estimatedReviewHours = 24;
  static const int _maxUploadBytes = 5 * 1024 * 1024;
  static const Set<String> _documentTypes = {'national_id', 'drivers_license', 'passport'};
  static const Set<String> _documentExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'pdf'};
  static const Map<String, String> _mimeTypes = {
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'pdf': 'application/pdf',
  };
  static const Map<String, String> _reasonMessages = {
    'image_unclear': 'The photo was blurry. Upload a clear one in good light.',
    'expired': 'This document has expired. Upload a valid one.',
    'name_mismatch': 'The name on this document doesn’t match your profile.',
    'wrong_document': 'This isn’t an ID we can accept. Upload a different one.',
  };

  static final List<MockRoute> routes = [
    MockRoute.get(VerificationEndpoints.status, (_) => _json(DateTime.now())),
    MockRoute.post(VerificationEndpoints.documents, _submit),
    MockRoute.post(VerificationEndpoints.documentFiles, _uploadFile),
    MockRoute.delete(VerificationEndpoints.documentFile, _deleteFile),
  ];

  static final List<_Item> _items = [
    _Item('selfie', 'selfie', 'Selfie', 'missing'),
    _Item('document', 'document', 'Identity document', 'missing'),
  ];

  static final Set<String> _fileIds = {};
  static int _fileCounter = 0;

  static DateTime? _submittedAt;
  static bool _isReviewed = false;
  static String? _documentType;
  static bool? _outcomeIsVerified;

  static String accountStatus(DateTime now) => _status(now);

  static ({DateTime at, bool isVerified})? get outcome {
    final submittedAt = _submittedAt;
    _settle(DateTime.now());
    final isVerified = _outcomeIsVerified;
    if (submittedAt == null || isVerified == null) return null;
    return (at: submittedAt.add(_reviewTime), isVerified: isVerified);
  }

  static final ValueNotifier<bool> rejectNextSelfie = ValueNotifier(false);

  static Object? selfie(MockRequest request) {
    if (rejectNextSelfie.value) {
      rejectNextSelfie.value = false;
      throw MockFailure(422, 'We couldn’t match your face.', code: 'face_not_matched');
    }
    final item = _item('selfie');
    if (_status(DateTime.now()) != 'pending') {
      item
        ..status = 'verified'
        ..reason = null;
    }
    return {'status': 'verified'};
  }

  static Object? _uploadFile(MockRequest request) {
    if (!_documentTypes.contains(request.body['documentType'])) {
      throw const MockFailure(422, 'Select a document type');
    }
    final file = request.body['file'];
    final name = file is Map ? file['name'] as String? ?? 'document.jpg' : 'document.jpg';
    final extension = name.split('.').last.toLowerCase();
    if (!_documentExtensions.contains(extension)) {
      throw const MockFailure(415, 'That file type isn’t supported.', code: 'unsupported_type');
    }
    final size = file is Map ? (file['length'] as num? ?? 0).toInt() : 0;
    if (size > _maxUploadBytes) throw const MockFailure(413, 'That photo is too big.', code: 'file_too_large');
    final id = 'file_${++_fileCounter}';
    _fileIds.add(id);
    return {'fileId': id, 'fileName': name, 'mimeType': _mimeTypes[extension] ?? 'image/jpeg', 'sizeBytes': size};
  }

  static Object? _deleteFile(MockRequest request) {
    _fileIds.remove(request.params['id']);
    return null;
  }

  static Object? _submit(MockRequest request) {
    final now = DateTime.now();
    if (_status(now) == 'pending') return _json(now);
    final type = request.body['documentType'];
    if (type is! String || type.isEmpty) throw const MockFailure(422, 'Select a document type');
    final fileIds = request.body['fileIds'];
    if (fileIds is! List || fileIds.isEmpty || fileIds.any((id) => !_fileIds.contains(id))) {
      throw const MockFailure(422, 'Upload at least one document');
    }
    _attach(type);
    final missing = [
      for (final item in _items)
        if (item.needsAction) item.id,
    ];
    if (missing.isNotEmpty) {
      throw MockFailure(422, 'A few things still need your attention.', code: 'incomplete', data: {'missing': missing});
    }
    _submittedAt = now;
    _isReviewed = false;
    _outcomeIsVerified = null;
    return _json(now);
  }

  static void _attach(String type) {
    if (!_documentTypes.contains(type)) {
      throw const MockFailure(422, 'We can’t accept that ID.', code: 'wrong_document');
    }
    _documentType = type;
    _item('document')
      ..status = 'pending'
      ..reason = null;
  }

  static _Item _item(String id) => _items.firstWhere((item) => item.id == id);

  static void _settle(DateTime now) {
    final submittedAt = _submittedAt;
    if (submittedAt == null || _isReviewed || now.isBefore(submittedAt.add(_reviewTime))) return;
    _isReviewed = true;
    for (final item in _items) {
      if (item.status != 'pending') continue;
      final isRejected = item.id == 'document' && _documentType == rejectedDocumentType;
      item
        ..status = isRejected ? 'rejected' : 'verified'
        ..reason = isRejected ? 'image_unclear' : null;
    }
    _outcomeIsVerified = _items.every((item) => item.status == 'verified');
  }

  static String _status(DateTime now) {
    _settle(now);
    final submittedAt = _submittedAt;
    if (submittedAt != null && now.isBefore(submittedAt.add(_reviewTime))) return 'pending';
    if (_items.every((item) => item.status == 'verified')) return 'verified';
    if (submittedAt == null) return 'unverified';
    return _items.any((item) => item.needsAction) ? 'rejected' : 'action_needed';
  }

  static Map<String, dynamic> _json(DateTime now) {
    final status = _status(now);
    return {
      'status': status,
      'submittedAt': _submittedAt == null ? null : _iso(_submittedAt!),
      'estimatedReviewHours': _estimatedReviewHours,
      'rejectionReason': _items.where((item) => item.status == 'rejected').firstOrNull?.reasonMessage,
      'items': [for (final item in _items) item.toJson()],
    };
  }

  static String _iso(DateTime time) => time.toUtc().toIso8601String();
}

class _Item {
  _Item(this.id, this.kind, this.label, this.status);

  final String id;
  final String kind;
  final String label;
  String status;
  String? reason;

  bool get needsAction => const {'missing', 'rejected', 'expired'}.contains(status);

  String? get reasonMessage => MockVerification._reasonMessages[reason];

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'label': label, 'status': status, 'reason': reasonMessage};
}
