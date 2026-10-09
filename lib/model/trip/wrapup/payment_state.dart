import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/trip/wrapup/payment.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum PaymentProblem {
  connection(CommonCopy.offlineTitle, '${CommonCopy.connectionBody} You haven’t been charged.'),
  server('Our side is struggling', CommonCopy.serverTrouble),
  unknown(CommonCopy.serverTitle, CommonCopy.serverTrouble);

  const PaymentProblem(this.title, this.message);

  final String title;
  final String message;

  static PaymentProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemServer() => server,
    _ => unknown,
  };
}

class PaymentNotice {
  const PaymentNotice(this.problem, {this.serverMessage});

  static const PaymentNotice offline = PaymentNotice(PaymentProblem.connection);

  final PaymentProblem problem;
  final String? serverMessage;

  String get title => problem.title;

  String get message => serverMessage == null || serverMessage!.isEmpty ? problem.message : serverMessage!;

  static PaymentNotice of(Object error) => PaymentNotice(PaymentProblem.of(error));
}

sealed class PaymentState {
  const PaymentState();
}

final class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

final class PaymentUnavailable extends PaymentState {
  const PaymentUnavailable(this.problem);

  final PaymentProblem problem;
}

sealed class PaymentLoaded extends PaymentState {
  const PaymentLoaded(this.payment);

  final TripPayment payment;
}

final class PaymentChoosing extends PaymentLoaded {
  const PaymentChoosing(super.payment, {this.selected, this.notice});

  final PaymentMethod? selected;
  final PaymentNotice? notice;

  PaymentChoosing withSelected(PaymentMethod method) => PaymentChoosing(payment, selected: method);
}

final class PaymentCardEntry extends PaymentLoaded {
  const PaymentCardEntry(super.payment, {this.notice});

  final PaymentNotice? notice;
}

final class PaymentProcessing extends PaymentLoaded {
  const PaymentProcessing(super.payment, {required this.method});

  final PaymentMethod method;
}

final class PaymentChecking extends PaymentLoaded {
  const PaymentChecking(super.payment, {required this.method});

  final PaymentMethod method;
}

enum CashWaitLink { live, offline, timedOut }

final class PaymentAwaitingDriver extends PaymentLoaded {
  const PaymentAwaitingDriver(super.payment, {this.link = CashWaitLink.live});

  final CashWaitLink link;

  PaymentAwaitingDriver withLink(CashWaitLink next) => PaymentAwaitingDriver(payment, link: next);
}

final class PaymentPaid extends PaymentLoaded {
  const PaymentPaid(super.payment);
}

final class PaymentDeclined extends PaymentLoaded {
  const PaymentDeclined(super.payment, {required this.reason});

  final PaymentDeclineReason reason;
}

final class PaymentUnconfirmed extends PaymentLoaded {
  const PaymentUnconfirmed(super.payment, {required this.method});

  static const String title = 'We’re still checking your payment';
  static const String message =
      'We haven’t heard back yet, so we don’t want to charge you twice. Check again in a moment.';

  final PaymentMethod method;
}
