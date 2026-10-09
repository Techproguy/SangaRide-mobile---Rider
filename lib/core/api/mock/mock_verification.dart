import 'package:sanga_ride/core/api/mock/mock_server.dart';
import 'package:sanga_ride/core/api/verification_endpoints.dart';

abstract final class MockVerification {
  static const String rejectedDocumentType = 'voters_card';
  static const Duration _reviewTime = Duration(seconds: 20);
  static const int _estimatedReviewHours = 24;
  static const int _maxUploadBytes = 5 * 1024 * 1024;
  static const Set<String> _documentTypes = {
    'national_id_card',
    'drivers_license',
    'voters_card',
    'international_passport',
  };
  static const Map<String, String> _reasonMessages = {
    'image_unclear': 'The photo was blurry. Upload a clear one in good light.',
    'expired': 'This document has expired. Upload a valid one.',
    'name_mismatch': 'The name on this document doesn’t match your profile.',
    'wrong_document': 'This isn’t an ID we can accept. Upload a different one.',
  };

  static final List<MockRoute> routes = [
    MockRoute.get(VerificationEndpoints.status, (_) => _json(DateTime.now())),
    MockRoute.post(VerificationEndpoints.submit, _submit),
  ];

  static final List<_Item> _items = [
    _Item('national_id', 'document', 'ID document', 'missing'),
    _Item('selfie', 'selfie', 'Selfie', 'missing'),
  ];

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

  static bool rejectNextSelfie = false;

  static Object? selfie(MockRequest request) {
    if (rejectNextSelfie) {
      rejectNextSelfie = false;
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

  static Object? _submit(MockRequest request) {
    final now = DateTime.now();
    if (_status(now) == 'pending') return _json(now);
    for (final document in (request.body['documents'] as List? ?? const [])) {
      _attach(Map<String, dynamic>.from(document as Map));
    }
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

  static void _attach(Map<String, dynamic> document) {
    final type = '${document['type']}';
    if (!_documentTypes.contains(type)) {
      throw const MockFailure(422, 'We can’t accept that ID.', code: 'wrong_document');
    }
    _documentType = type;
    _item('national_id')
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
      final isRejected = item.id == 'national_id' && _documentType == rejectedDocumentType;
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
      'items': [for (final item in _items) item.toJson()],
      'serverTime': _iso(now),
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'label': label,
    'status': status,
    'reason': reason == null ? null : {'code': reason, 'message': MockVerification._reasonMessages[reason]},
    'expiresAt': null,
    if (kind == 'document') ...{
      'upload': {
        'maxBytes': MockVerification._maxUploadBytes,
        'formats': ['jpg', 'png'],
      },
      'documentTypes': MockVerification._documentTypes.toList(),
    },
  };
}
