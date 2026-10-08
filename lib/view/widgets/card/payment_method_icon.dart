import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/payment.dart';

abstract final class PaymentMethodIcon {
  static IconData of(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.card => Icons.credit_card_rounded,
    PaymentMethod.wallet => Icons.account_balance_wallet_outlined,
  };
}
