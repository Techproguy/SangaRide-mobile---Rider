import 'dart:collection';

import 'package:sanga_ride/model/trip/wrapup/payment.dart';

class SensitiveBody extends UnmodifiableMapView<String, dynamic> {
  SensitiveBody(super.source);

  @override
  String toString() => '<redacted>';
}

class CardDetails {
  const CardDetails({required this.number, required this.expiry, required this.cvv, this.pin = ''});

  final String number;
  final String expiry;
  final String cvv;
  final String pin;

  String get last4 => number.substring(number.length - 4);
}

class PaymentRequest {
  const PaymentRequest.cash() : method = PaymentMethod.cash, cardToken = null;

  const PaymentRequest.card(String this.cardToken) : method = PaymentMethod.card;

  const PaymentRequest.wallet() : method = PaymentMethod.wallet, cardToken = null;

  const PaymentRequest.groupWallet() : method = PaymentMethod.groupWallet, cardToken = null;

  final PaymentMethod method;
  final String? cardToken;

  Map<String, dynamic> toJson() {
    final token = cardToken;
    if (token == null) return {'method': method.code};
    return SensitiveBody({
      'method': method.code,
      'card': SensitiveBody({'token': token}),
    });
  }
}
