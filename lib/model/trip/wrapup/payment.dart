enum PaymentMethod {
  cash('cash', 'Cash', 'Hand it to your driver', 'Payment confirmed', 'Your driver confirmed your cash payment.'),
  card(
    'card',
    'Card',
    'Pay securely with your debit or credit card',
    'Payment complete',
    'Your card payment went through.',
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

  static PaymentMethod fromCode(String code) =>
      tryFromCode(code) ?? (throw FormatException('Unknown payment method: $code'));
}

enum PaymentStatus {
  pending('pending'),
  awaitingDriver('awaiting_driver'),
  succeeded('succeeded'),
  declined('declined'),
  failed('failed');

  const PaymentStatus(this.code);

  final String code;

  static PaymentStatus fromCode(String code) => values.firstWhere(
    (status) => status.code == code,
    orElse: () => throw FormatException('Unknown payment status: $code'),
  );
}

enum PaymentDeclineReason {
  cardDeclined('card_declined', 'Card declined', 'Your bank declined this card.'),
  cardExpired('card_expired', 'Card expired', 'This card has expired.'),
  unknown('unknown', 'Payment didn’t go through', 'We couldn’t take that payment. Give it another go.');

  const PaymentDeclineReason(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  static PaymentDeclineReason fromCode(String? code) =>
      values.firstWhere((reason) => reason.code == code, orElse: () => unknown);
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
  });

  factory TripPayment.fromJson(Map<String, dynamic> json) {
    final paidAt = json['paidAt'] as String?;
    final declineCode = json['declineCode'] as String?;
    return TripPayment(
      tripId: json['tripId'] as String,
      amount: (json['amount'] as num).toInt(),
      status: PaymentStatus.fromCode(json['status'] as String),
      allowedMethods: [for (final code in json['allowedMethods'] as List) ?PaymentMethod.tryFromCode(code as String)],
      method: PaymentMethod.tryFromCode(json['method'] as String?),
      last4: json['last4'] as String?,
      paidAt: paidAt == null ? null : DateTime.parse(paidAt).toLocal(),
      lastMethod: PaymentMethod.tryFromCode(json['lastMethod'] as String?),
      declineReason: declineCode == null ? null : PaymentDeclineReason.fromCode(declineCode),
    );
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

  PaymentMethod? get preferredMethod {
    if (lastMethod != null && allowedMethods.contains(lastMethod)) return lastMethod;
    return allowedMethods.isEmpty ? null : allowedMethods.first;
  }

  String get paidTitle => method?.paidTitle ?? 'Payment complete';

  String get paidMessage => method?.paidMessage ?? 'Your payment went through.';

  String get paidSummary => switch ((method, last4)) {
    (PaymentMethod.card, final String last4) => 'Card •••• $last4',
    (final PaymentMethod method?, _) => method.label,
    _ => 'Paid',
  };
}
