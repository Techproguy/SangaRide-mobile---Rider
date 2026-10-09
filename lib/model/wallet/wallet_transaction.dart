import 'package:sanga_ride_core/sanga_ride_core.dart';

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
      enumByCode(values, code, (kind) => kind.code, TransactionKind.adjustment);
}

enum TransactionStatus {
  pending('pending', 'Pending'),
  completed('completed', 'Completed'),
  failed('failed', 'Failed'),
  reversed('reversed', 'Reversed'),
  unknown('unknown', 'Updating');

  const TransactionStatus(this.code, this.label);

  final String code;
  final String label;

  static TransactionStatus fromCode(String? code) =>
      enumByCode(values, code, (status) => status.code, TransactionStatus.unknown);
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
    this.isDelivery = false,
  });

  factory TransactionMeta.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return TransactionMeta(
      tripId: reader.strOrNull('tripId'),
      route: reader.strOrNull('route'),
      fare: reader.intOrNull('fare'),
      paymentMethod: reader.strOrNull('paymentMethod'),
      method: reader.strOrNull('method'),
      cardLast4: reader.strOrNull('cardLast4'),
      cardBrand: reader.strOrNull('cardBrand'),
      topUpId: reader.strOrNull('topUpId'),
      expiresAt: reader.timeOrNull('expiresAt')?.toLocal(),
      note: reader.strOrNull('note'),
      failureReason: reader.strOrNull('failureReason'),
      isDelivery: reader.strOrNull('tripKind') == 'delivery',
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
  final bool isDelivery;

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

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return WalletTransaction(
      id: reader.str('id'),
      kind: TransactionKind.fromCode(reader.strOrNull('kind')),
      title: reader.strOr('title', ''),
      amount: reader.integer('amount'),
      status: TransactionStatus.fromCode(reader.strOrNull('status')),
      createdAt: reader.time('createdAt').toLocal(),
      reference: reader.strOr('reference', ''),
      meta: TransactionMeta.fromJson(reader.objectOrNull('meta')?.raw ?? const {}),
    );
  }

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
