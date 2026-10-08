import 'package:sanga_ride/model/verification/verification_status.dart';

enum VerificationItemKind {
  document('document'),
  selfie('selfie');

  const VerificationItemKind(this.code);

  final String code;

  static VerificationItemKind fromCode(Object? code) =>
      values.where((kind) => kind.code == '$code').firstOrNull ?? document;
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

  static ItemStatus fromCode(Object? code) => values.where((status) => status.code == '$code').firstOrNull ?? missing;
}

class ItemReason {
  const ItemReason({required this.code, required this.message});

  factory ItemReason.fromJson(Map<String, dynamic> json) =>
      ItemReason(code: json['code'] as String, message: json['message'] as String);

  final String code;
  final String message;
}

class VerificationItem {
  const VerificationItem({
    required this.id,
    required this.kind,
    required this.label,
    required this.status,
    required this.reason,
    required this.expiresAt,
  });

  factory VerificationItem.fromJson(Map<String, dynamic> json) => VerificationItem(
    id: json['id'] as String,
    kind: VerificationItemKind.fromCode(json['kind']),
    label: json['label'] as String,
    status: ItemStatus.fromCode(json['status']),
    reason: json['reason'] == null ? null : ItemReason.fromJson(Map<String, dynamic>.from(json['reason'] as Map)),
    expiresAt: json['expiresAt'] == null ? null : DateTime.parse('${json['expiresAt']}').toLocal(),
  );

  final String id;
  final VerificationItemKind kind;
  final String label;
  final ItemStatus status;
  final ItemReason? reason;
  final DateTime? expiresAt;

  bool get needsAction => status.needsAction;
}

class Verification {
  const Verification({
    required this.status,
    required this.submittedAt,
    required this.estimatedReviewHours,
    required this.items,
  });

  factory Verification.fromJson(Map<String, dynamic> json) => Verification(
    status: VerificationStatus.fromCode(json['status']),
    submittedAt: json['submittedAt'] == null ? null : DateTime.parse('${json['submittedAt']}').toLocal(),
    estimatedReviewHours: (json['estimatedReviewHours'] as num?)?.toInt() ?? 24,
    items: [
      for (final item in json['items'] as List) VerificationItem.fromJson(Map<String, dynamic>.from(item as Map)),
    ],
  );

  final VerificationStatus status;
  final DateTime? submittedAt;
  final int estimatedReviewHours;
  final List<VerificationItem> items;

  List<VerificationItem> get actionItems => [
    for (final item in items)
      if (item.needsAction) item,
  ];

  VerificationItem? get nextItem => actionItems.firstOrNull;

  bool get isReadyToSubmit =>
      status != VerificationStatus.pending && status != VerificationStatus.verified && actionItems.isEmpty;

  VerificationItem? itemById(String id) => items.where((item) => item.id == id).firstOrNull;
}
