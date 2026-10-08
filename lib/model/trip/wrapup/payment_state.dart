import 'package:sanga_ride/model/trip/wrapup/payment.dart';

sealed class PaymentState {
  const PaymentState();
}

final class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

final class PaymentUnavailable extends PaymentState {
  const PaymentUnavailable();
}

sealed class PaymentLoaded extends PaymentState {
  const PaymentLoaded(this.payment);

  final TripPayment payment;
}

final class PaymentChoosing extends PaymentLoaded {
  const PaymentChoosing(super.payment, {required this.selected});

  final PaymentMethod selected;

  PaymentChoosing withSelected(PaymentMethod method) => PaymentChoosing(payment, selected: method);
}

final class PaymentCardEntry extends PaymentLoaded {
  const PaymentCardEntry(super.payment);
}

final class PaymentProcessing extends PaymentLoaded {
  const PaymentProcessing(super.payment, {required this.method});

  final PaymentMethod method;
}

final class PaymentAwaitingDriver extends PaymentLoaded {
  const PaymentAwaitingDriver(super.payment);
}

final class PaymentPaid extends PaymentLoaded {
  const PaymentPaid(super.payment);
}

final class PaymentDeclined extends PaymentLoaded {
  const PaymentDeclined(super.payment, {required this.reason});

  final PaymentDeclineReason reason;
}

final class PaymentFailed extends PaymentLoaded {
  const PaymentFailed(super.payment, {required this.method});

  static const String title = 'We couldn’t confirm your payment';
  static const String message =
      'We couldn’t reach the server, so we’re not sure it went through. Check your bank app before you try again.';

  final PaymentMethod method;
}
