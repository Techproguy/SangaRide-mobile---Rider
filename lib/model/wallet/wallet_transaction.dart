enum TransactionKind {
  rideEarning('ride_earning'),
  deliveryEarning('delivery_earning'),
  tip('tip'),
  withdrawal('withdrawal'),
  topUp('top_up'),
  ridePayment('ride_payment'),
  refund('refund'),
  commission('commission'),
  adjustment('adjustment');

  const TransactionKind(this.code);

  final String code;

  static TransactionKind fromCode(String? code) =>
      values.where((kind) => kind.code == code).firstOrNull ?? TransactionKind.adjustment;
}

enum TransactionStatus {
  pending('pending', 'Pending'),
  completed('completed', 'Completed'),
  failed('failed', 'Failed'),
  reversed('reversed', 'Reversed');

  const TransactionStatus(this.code, this.label);

  final String code;
  final String label;

  static TransactionStatus fromCode(String? code) =>
      values.where((status) => status.code == code).firstOrNull ?? TransactionStatus.completed;
}

enum TransactionFilter {
  all('All', []),
  topUps('Top ups', [TransactionKind.topUp]),
  rides('Rides', [TransactionKind.ridePayment]),
  credits('Refunds and credits', [TransactionKind.refund, TransactionKind.adjustment]);

  const TransactionFilter(this.label, this.kinds);

  final String label;
  final List<TransactionKind> kinds;

  String? get query => kinds.isEmpty ? null : kinds.map((kind) => kind.code).join(',');
}

class TransactionMeta {
  const TransactionMeta({
    this.tripId,
    this.route,
    this.fare,
    this.paymentMethod,
    this.method,
    this.cardLast4,
    this.cardBrand,
    this.topUpId,
    this.expiresAt,
    this.note,
    this.failureReason,
  });

  factory TransactionMeta.fromJson(Map<String, dynamic> json) {
    final expiresAt = json['expiresAt'] as String?;
    return TransactionMeta(
      tripId: json['tripId'] as String?,
      route: json['route'] as String?,
      fare: (json['fare'] as num?)?.toInt(),
      paymentMethod: json['paymentMethod'] as String?,
      method: json['method'] as String?,
      cardLast4: json['cardLast4'] as String?,
      cardBrand: json['cardBrand'] as String?,
      topUpId: json['topUpId'] as String?,
      expiresAt: expiresAt == null ? null : DateTime.parse(expiresAt).toLocal(),
      note: json['note'] as String?,
      failureReason: json['failureReason'] as String?,
    );
  }

  final String? tripId;
  final String? route;
  final int? fare;
  final String? paymentMethod;
  final String? method;
  final String? cardLast4;
  final String? cardBrand;
  final String? topUpId;
  final DateTime? expiresAt;
  final String? note;
  final String? failureReason;

  bool get isTransfer => method == 'transfer';
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.reference,
    required this.meta,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
    id: json['id'] as String,
    kind: TransactionKind.fromCode(json['kind'] as String?),
    title: json['title'] as String,
    amount: (json['amount'] as num).toInt(),
    status: TransactionStatus.fromCode(json['status'] as String?),
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    reference: json['reference'] as String,
    meta: TransactionMeta.fromJson(Map<String, dynamic>.from((json['meta'] as Map?) ?? const {})),
  );

  final String id;
  final TransactionKind kind;
  final String title;
  final int amount;
  final TransactionStatus status;
  final DateTime createdAt;
  final String reference;
  final TransactionMeta meta;

  bool get isCredit => amount > 0;

  bool get isPending => status == TransactionStatus.pending;

  bool get isPendingTransfer => kind == TransactionKind.topUp && isPending && meta.isTransfer && meta.topUpId != null;
}

class TransactionDay {
  const TransactionDay(this.date, this.entries);

  final DateTime date;
  final List<WalletTransaction> entries;

  static List<TransactionDay> group(List<WalletTransaction> entries) {
    final days = <TransactionDay>[];
    for (final entry in entries) {
      final day = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      if (days.isNotEmpty && days.last.date == day) {
        days.last.entries.add(entry);
      } else {
        days.add(TransactionDay(day, [entry]));
      }
    }
    return days;
  }
}
