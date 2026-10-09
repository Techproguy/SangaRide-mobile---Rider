import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/model/groups/group_kind.dart';
import 'package:sanga_ride/model/trip/server_time.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum PaymentMethod {
  cash('cash', 'Cash', 'Hand it to your driver', 'Payment confirmed', 'Your driver confirmed your cash payment.'),
  card(
    'card',
    'Card',
    'Pay securely with your debit or credit card',
    'Payment complete',
    'Your card payment went through.',
  ),
  wallet(
    'wallet',
    'Wallet',
    'Pay from your Sanga balance',
    'Paid from your wallet',
    'Your wallet payment went through.',
  ),
  groupWallet(
    'group_wallet',
    'Group wallet',
    'Charged to the group',
    'Paid by the group wallet',
    'The group wallet covered this ride.',
  );

  const PaymentMethod(this.code, this.label, this.subtitle, this.paidTitle, this.paidMessage);

  final String code;
  final String label;
  final String subtitle;
  final String paidTitle;
  final String paidMessage;

  static PaymentMethod? tryFromCode(String? code) {
    for (final method in values) {
      if (method.code == code) return method;
    }
    return null;
  }
}

enum PaymentStatus {
  pending('pending'),
  awaitingDriver('awaiting_driver'),
  processing('processing'),
  succeeded('succeeded'),
  declined('declined'),
  failed('failed'),
  unknown('unknown');

  const PaymentStatus(this.code);

  final String code;

  bool get isTerminal => this == succeeded || this == declined || this == failed;

  static PaymentStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, unknown);
}

enum PaymentDeclineReason {
  cardDeclined(ServerCode.cardDeclined, 'Card declined', 'Your bank declined this card.'),
  cardExpired(ServerCode.cardExpired, 'Card expired', 'This card has expired.'),
  insufficientBalance(
    ServerCode.insufficientBalance,
    'Not enough in your wallet',
    'Your wallet balance is lower than this fare. Top up to use it, or pay another way.',
  ),
  groupWalletShort(
    ServerCode.groupWalletShort,
    'The group wallet is short',
    'There isn’t enough in the group wallet for this ride. Ask an admin to top it up, or pay another way.',
  ),
  unknown('unknown', 'Payment didn’t go through', 'We couldn’t take that payment. Give it another go.');

  const PaymentDeclineReason(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  static PaymentDeclineReason fromCode(String? code) =>
      codedEnum(values, (reason) => reason.code, code, orElse: unknown);
}

class PaymentGroup {
  const PaymentGroup({required this.id, required this.kind, required this.name});

  factory PaymentGroup.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return PaymentGroup(
      id: reader.str('id'),
      kind: GroupKind.tryFromCode(reader.strOrNull('kind')),
      name: reader.strOr('name', ''),
    );
  }

  final String id;
  final GroupKind? kind;
  final String name;
}

class TripPayment {
  const TripPayment({
    required this.tripId,
    required this.amount,
    required this.status,
    required this.allowedMethods,
    this.method,
    this.last4,
    this.paidAt,
    this.lastMethod,
    this.declineReason,
    this.declineMessage,
    this.group,
    this.cashWaitExpiresAt,
  });

  factory TripPayment.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final group = reader.objectOrNull('group');
    return TripPayment(
      tripId: reader.str('tripId'),
      amount: reader.integer('amount'),
      status: PaymentStatus.fromCode(reader.strOrNull('status')),
      allowedMethods: [for (final code in reader.strings('allowedMethods')) ?PaymentMethod.tryFromCode(code)],
      method: PaymentMethod.tryFromCode(reader.strOrNull('method')),
      last4: reader.strOrNull('last4'),
      paidAt: reader.timeOrNull('paidAt')?.toLocal(),
      lastMethod: PaymentMethod.tryFromCode(reader.strOrNull('lastMethod')),
      declineReason: reader.has('declineCode') ? PaymentDeclineReason.fromCode(reader.strOrNull('declineCode')) : null,
      declineMessage: reader.strOrNull('declineMessage'),
      group: group == null ? null : _groupOf(group),
      cashWaitExpiresAt: deviceDeadlineOrNull(reader.strOrNull('cashWaitExpiresAt')),
    );
  }

  static PaymentGroup? _groupOf(JsonReader reader) {
    try {
      return PaymentGroup.fromJson(reader.raw);
    } catch (_) {
      return null;
    }
  }

  final String tripId;
  final int amount;
  final PaymentStatus status;
  final List<PaymentMethod> allowedMethods;
  final PaymentMethod? method;
  final String? last4;
  final DateTime? paidAt;
  final PaymentMethod? lastMethod;
  final PaymentDeclineReason? declineReason;
  final String? declineMessage;
  final PaymentGroup? group;
  final DateTime? cashWaitExpiresAt;

  PaymentMethod? get preferredMethod {
    if (lastMethod != null && allowedMethods.contains(lastMethod)) return lastMethod;
    return allowedMethods.isEmpty ? null : allowedMethods.first;
  }

  String get paidTitle => method?.paidTitle ?? 'Payment complete';

  String get paidMessage => method?.paidMessage ?? 'Your payment went through.';
}
