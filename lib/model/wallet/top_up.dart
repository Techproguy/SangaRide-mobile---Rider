import 'package:sanga_ride_core/sanga_ride_core.dart';

enum TopUpMethod {
  transfer('transfer', 'Transfer', 'Send from any bank app'),
  card('card', 'Card', 'Pay with a debit or credit card');

  const TopUpMethod(this.code, this.label, this.subtitle);

  final String code;
  final String label;
  final String subtitle;

  static TopUpMethod? tryFromCode(String? code) {
    for (final method in values) {
      if (method.code == code) return method;
    }
    return null;
  }
}

enum TopUpStatus {
  pending('pending'),
  completed('completed'),
  failed('failed'),
  requiresAction('requires_action'),
  awaitingTransfer('awaiting_transfer'),
  expired('expired'),
  unknown('unknown');

  const TopUpStatus(this.code);

  final String code;

  bool get isOpen => this == pending || this == requiresAction || this == awaitingTransfer;

  static TopUpStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, TopUpStatus.unknown);
}

enum TopUpActionType {
  otp('otp'),
  threeDs('3ds');

  const TopUpActionType(this.code);

  final String code;

  static TopUpActionType? tryFromCode(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

class TopUpAction {
  const TopUpAction({required this.type, required this.message});

  final TopUpActionType? type;
  final String message;

  static TopUpAction? tryFromJson(JsonReader? reader) {
    if (reader == null) return null;
    return TopUpAction(
      type: TopUpActionType.tryFromCode(reader.strOrNull('type')),
      message: reader.strOr('message', ''),
    );
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
    this.createdAt,
    this.failureCode,
    this.balance,
  });

  factory TopUp.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return TopUp(
      id: reader.str('id'),
      status: TopUpStatus.fromCode(reader.strOrNull('status')),
      action: TopUpAction.tryFromJson(reader.objectOrNull('action')),
      amount: reader.intOrNull('amount'),
      method: TopUpMethod.tryFromCode(reader.strOrNull('method')),
      expiresAt: reader.timeOrNull('expiresAt'),
      createdAt: reader.timeOrNull('createdAt'),
      failureCode: reader.strOrNull('failureCode'),
      balance: reader.intOrNull('balance'),
    );
  }

  final String id;
  final TopUpStatus status;
  final TopUpAction? action;
  final int? amount;
  final TopUpMethod? method;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? failureCode;
  final int? balance;
}

class TransferExpectation {
  const TransferExpectation({required this.id, required this.amount, required this.expiresAt, this.createdAt});

  final String id;
  final int amount;
  final DateTime? expiresAt;
  final DateTime? createdAt;
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
  connection(
    'connection',
    'You’re offline',
    'We couldn’t reach the server and nothing was charged. Check your connection and give it another go.',
  ),
  unknown('unknown', 'Top up didn’t go through', 'Something went wrong on our side. Give it another go.');

  const TopUpFailure(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  static TopUpFailure fromCode(String? code) =>
      enumByCode(values, code, (failure) => failure.code, TopUpFailure.unknown);

  static TopUpFailure of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => fromCode(code),
    _ => unknown,
  };
}

class SavedTopUp {
  const SavedTopUp({
    required this.intentKey,
    required this.method,
    required this.amount,
    this.topUpId,
    this.status,
    this.savedCardId,
  });

  static SavedTopUp? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final reader = JsonReader(json);
    final method = TopUpMethod.tryFromCode(reader.strOrNull('method'));
    final key = reader.strOrNull('intentKey');
    final amount = reader.intOrNull('amount');
    if (method == null || key == null || amount == null) return null;
    final status = reader.strOrNull('status');
    return SavedTopUp(
      intentKey: key,
      method: method,
      amount: amount,
      topUpId: reader.strOrNull('topUpId'),
      status: status == null ? null : TopUpStatus.fromCode(status),
      savedCardId: reader.strOrNull('savedCardId'),
    );
  }

  final String intentKey;
  final TopUpMethod method;
  final int amount;
  final String? topUpId;
  final TopUpStatus? status;
  final String? savedCardId;

  bool get isResumable => topUpId != null && (status == null || status!.isOpen);

  Map<String, dynamic> toJson() => {
    'intentKey': intentKey,
    'method': method.code,
    'amount': amount,
    'topUpId': ?topUpId,
    'status': ?status?.code,
    'savedCardId': ?savedCardId,
  };

  SavedTopUp copyWith({String? topUpId, TopUpStatus? status}) => SavedTopUp(
    intentKey: intentKey,
    method: method,
    amount: amount,
    topUpId: topUpId ?? this.topUpId,
    status: status ?? this.status,
    savedCardId: savedCardId,
  );
}
