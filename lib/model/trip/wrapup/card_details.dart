import 'dart:collection';

import 'package:sanga_ride/model/trip/wrapup/payment.dart';

class SensitiveBody extends UnmodifiableMapView<String, dynamic> {
  SensitiveBody(super.source);

  @override
  String toString() => '<redacted>';
}

class CardDetails {
  const CardDetails({required this.number, required this.expiry, required this.cvv, required this.pin});

  final String number;
  final String expiry;
  final String cvv;
  final String pin;

  String get last4 => number.substring(number.length - 4);
}

class PaymentRequest {
  const PaymentRequest.cash() : method = PaymentMethod.cash, card = null;

  const PaymentRequest.card(CardDetails this.card) : method = PaymentMethod.card;

  final PaymentMethod method;
  final CardDetails? card;

  Map<String, dynamic> toJson() {
    final details = card;
    if (details == null) return {'method': method.code};
    return SensitiveBody({
      'method': method.code,
      'card': SensitiveBody({
        'number': details.number,
        'expiry': details.expiry,
        'cvv': details.cvv,
        'pin': details.pin,
      }),
    });
  }
}
