enum TopUpMethod {
  transfer('transfer', 'Transfer', 'Send from any bank app'),
  card('card', 'Card', 'Pay with a debit or credit card');

  const TopUpMethod(this.code, this.label, this.subtitle);

  final String code;
  final String label;
  final String subtitle;
}

enum TopUpStatus {
  pending('pending'),
  completed('completed'),
  failed('failed'),
  requiresAction('requires_action'),
  awaitingTransfer('awaiting_transfer'),
  expired('expired');

  const TopUpStatus(this.code);

  final String code;

  static TopUpStatus fromCode(String? code) =>
      values.where((status) => status.code == code).firstOrNull ?? TopUpStatus.pending;
}

enum TopUpActionType {
  otp('otp'),
  threeDs('3ds');

  const TopUpActionType(this.code);

  final String code;

  static TopUpActionType? tryFromCode(String? code) => values.where((type) => type.code == code).firstOrNull;
}

class TopUpAction {
  const TopUpAction({required this.type, required this.message});

  final TopUpActionType? type;
  final String message;

  static TopUpAction? tryFromJson(Object? json) {
    if (json is! Map) return null;
    return TopUpAction(type: TopUpActionType.tryFromCode(json['type'] as String?), message: json['message'] as String);
  }
}

class TopUp {
  const TopUp({
    required this.id,
    required this.status,
    this.action,
    this.amount,
    this.method,
    this.expiresAt,
    this.failureCode,
  });

  factory TopUp.fromJson(Map<String, dynamic> json) {
    final expiresAt = json['expiresAt'] as String?;
    return TopUp(
      id: json['id'] as String,
      status: TopUpStatus.fromCode(json['status'] as String?),
      action: TopUpAction.tryFromJson(json['action']),
      amount: (json['amount'] as num?)?.toInt(),
      method: TopUpMethod.values.where((method) => method.code == json['method']).firstOrNull,
      expiresAt: expiresAt == null ? null : DateTime.parse(expiresAt).toLocal(),
      failureCode: json['failureCode'] as String?,
    );
  }

  final String id;
  final TopUpStatus status;
  final TopUpAction? action;
  final int? amount;
  final TopUpMethod? method;
  final DateTime? expiresAt;
  final String? failureCode;
}

class TransferExpectation {
  const TransferExpectation({required this.id, required this.amount, required this.expiresAt});

  final String id;
  final int amount;
  final DateTime? expiresAt;
}

enum TopUpFailure {
  cardDeclined('card_declined', 'Card declined', 'Your bank declined this card. Try another card or pay by transfer.'),
  insufficientFunds(
    'insufficient_funds',
    'Not enough in that account',
    'That card doesn’t have enough money for this top up. Try a smaller amount or another card.',
  ),
  amountOutOfRange(
    'amount_out_of_range',
    'That amount doesn’t work',
    'Pick an amount inside the limits and give it another go.',
  ),
  checkNotSupported(
    'check_not_supported',
    'This card needs another check',
    'This card needs a check we can’t do in the app. Try another card or pay by transfer.',
  ),
  transferExpired(
    'transfer_expired',
    'That transfer window closed',
    'We didn’t get your transfer in time. If you already sent it, it will show up in your wallet as soon as it lands.',
  ),
  unconfirmed(
    'unconfirmed',
    'We couldn’t confirm your top up',
    'We couldn’t reach the server, so we’re not sure it went through. Check your balance before you try again.',
  ),
  unknown('unknown', 'Top up didn’t go through', 'Something went wrong on our side. Give it another go.');

  const TopUpFailure(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  bool get mayHaveGoneThrough => this == unconfirmed;

  static TopUpFailure fromCode(String? code) => values.where((failure) => failure.code == code).firstOrNull ?? unknown;
}
