import 'package:sanga_ride/model/wallet/top_up.dart';

class TopUpDraft {
  const TopUpDraft({this.amount, this.method = TopUpMethod.card, this.savedCardId, this.saveCard = false});

  final int? amount;
  final TopUpMethod method;
  final String? savedCardId;
  final bool saveCard;

  TopUpDraft copyWith({
    int? Function()? amount,
    TopUpMethod? method,
    String? Function()? savedCardId,
    bool? saveCard,
  }) => TopUpDraft(
    amount: amount == null ? this.amount : amount(),
    method: method ?? this.method,
    savedCardId: savedCardId == null ? this.savedCardId : savedCardId(),
    saveCard: saveCard ?? this.saveCard,
  );
}

enum OtpStage { ready, verifying, mismatch, failed }

sealed class TopUpState {
  const TopUpState();
}

final class TopUpEditing extends TopUpState {
  const TopUpEditing();
}

final class TopUpSubmitting extends TopUpState {
  const TopUpSubmitting(this.method);

  final TopUpMethod method;
}

final class TopUpChecking extends TopUpState {
  const TopUpChecking(this.method);

  final TopUpMethod method;
}

final class TopUpUnknown extends TopUpState {
  const TopUpUnknown(this.method);

  final TopUpMethod method;
}

final class TopUpOtp extends TopUpState {
  const TopUpOtp(this.topUp, this.action, {this.stage = OtpStage.ready, this.failure});

  final TopUp topUp;
  final TopUpAction action;
  final OtpStage stage;
  final TopUpFailure? failure;

  TopUpOtp withStage(OtpStage next, {TopUpFailure? failure}) => TopUpOtp(topUp, action, stage: next, failure: failure);
}

final class TopUpConfirming extends TopUpState {
  const TopUpConfirming(this.topUp);

  final TopUp topUp;
}

final class TopUpTransferWatching extends TopUpState {
  const TopUpTransferWatching(this.expectation);

  final TransferExpectation expectation;
}

final class TopUpTransferDelayed extends TopUpState {
  const TopUpTransferDelayed(this.expectation);

  final TransferExpectation expectation;
}

final class TopUpSucceeded extends TopUpState {
  const TopUpSucceeded({required this.amount, required this.balance, required this.method});

  final int amount;
  final int? balance;
  final TopUpMethod method;
}

final class TopUpFailed extends TopUpState {
  const TopUpFailed(this.failure, {required this.method, this.canRetryAsIs = false});

  final TopUpFailure failure;
  final TopUpMethod method;
  final bool canRetryAsIs;
}
