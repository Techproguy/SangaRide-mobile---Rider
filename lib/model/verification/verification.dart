import 'package:sanga_ride_core/sanga_ride_core.dart';

enum VerificationItemKind {
  document('document'),
  selfie('selfie');

  const VerificationItemKind(this.code);

  final String code;

  static VerificationItemKind fromCode(Object? code) =>
      codedEnum(values, (kind) => kind.code, code, orElse: VerificationItemKind.document);
}

enum ItemStatus {
  missing('missing'),
  pending('pending'),
  verified('verified'),
  rejected('rejected'),
  expiring('expiring'),
  expired('expired');

  const ItemStatus(this.code);

  final String code;

  bool get needsAction => this == missing || this == rejected || this == expired;

  static ItemStatus fromCode(Object? code) =>
      codedEnum(values, (status) => status.code, code, orElse: ItemStatus.missing);
}

class ItemReason {
  const ItemReason({required this.code, required this.message});

  static ItemReason? tryFromReader(JsonReader reader) {
    final detail = reader.objectOrNull('reason');
    if (detail != null) return ItemReason(code: detail.strOr('code', ''), message: detail.strOr('message', ''));
    final message = reader.strOrNull('reason');
    return message == null ? null : ItemReason(code: '', message: message);
  }

  final String code;
  final String message;
}

class UploadRules {
  const UploadRules({required this.maxBytes, required this.formats});

  static UploadRules? tryFromReader(JsonReader? reader) {
    if (reader == null) return null;
    final maxBytes = reader.intOrNull('maxBytes');
    if (maxBytes == null) return null;
    return UploadRules(maxBytes: maxBytes, formats: reader.strings('formats'));
  }

  final int maxBytes;
  final List<String> formats;

  String get summary {
    final size = maxBytes >= 1048576 ? '${(maxBytes / 1048576).round()}MB' : '${(maxBytes / 1024).round()}KB';
    final kinds = formats.map((format) => format.toUpperCase()).join(' or ');
    return kinds.isEmpty ? 'Up to $size each' : 'Accepted formats: $kinds, up to $size each';
  }
}

class VerificationItem {
  const VerificationItem({
    required this.id,
    required this.kind,
    required this.label,
    required this.status,
    required this.reason,
    required this.expiresAt,
    this.uploadRules,
    this.documentTypes = const [],
  });

  factory VerificationItem.fromReader(JsonReader reader) => VerificationItem(
    id: reader.str('id'),
    kind: VerificationItemKind.fromCode(reader.strOrNull('kind')),
    label: reader.strOr('label', ''),
    status: ItemStatus.fromCode(reader.strOrNull('status')),
    reason: ItemReason.tryFromReader(reader),
    expiresAt: reader.timeOrNull('expiresAt')?.toLocal(),
    uploadRules: UploadRules.tryFromReader(reader.objectOrNull('upload')),
    documentTypes: reader.strings('documentTypes'),
  );

  final String id;
  final VerificationItemKind kind;
  final String label;
  final ItemStatus status;
  final ItemReason? reason;
  final DateTime? expiresAt;
  final UploadRules? uploadRules;
  final List<String> documentTypes;

  bool get needsAction => status.needsAction;

  VerificationItem withReason(ItemReason reason) => VerificationItem(
    id: id,
    kind: kind,
    label: label,
    status: status,
    reason: reason,
    expiresAt: expiresAt,
    uploadRules: uploadRules,
    documentTypes: documentTypes,
  );
}

class Verification {
  const Verification({
    required this.status,
    required this.submittedAt,
    required this.estimatedReviewHours,
    required this.items,
  });

  factory Verification.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final submittedAt = reader.timeOrNull('submittedAt')?.toLocal();
    final rejection = reader.strOrNull('rejectionReason');
    final items = [
      for (final item in reader.listOf('items', VerificationItem.fromReader))
        if (rejection != null && item.status == ItemStatus.rejected && item.reason == null)
          item.withReason(ItemReason(code: '', message: rejection))
        else
          item,
    ];
    final reported = VerificationStatus.fromCode(reader.strOrNull('status'));
    final isUnsent =
        reported == VerificationStatus.pending && submittedAt == null && items.any((item) => item.needsAction);
    return Verification(
      status: isUnsent ? VerificationStatus.unverified : reported,
      submittedAt: submittedAt,
      estimatedReviewHours: reader.intOr('estimatedReviewHours', 24),
      items: items,
    );
  }

  final VerificationStatus status;
  final DateTime? submittedAt;
  final int estimatedReviewHours;
  final List<VerificationItem> items;

  List<VerificationItem> get actionItems => [
    for (final item in items)
      if (item.needsAction) item,
  ];

  VerificationItem? get nextItem => actionItems.firstOrNull;

  VerificationItem? get documentItem {
    for (final item in items) {
      if (item.kind == VerificationItemKind.document) return item;
    }
    return null;
  }

  bool get isReadyToSubmit =>
      status != VerificationStatus.pending && status != VerificationStatus.verified && actionItems.isEmpty;
}
