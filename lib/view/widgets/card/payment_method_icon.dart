import 'package:flutter/material.dart';
import 'package:sanga_ride/model/groups/group_kind.dart';
import 'package:sanga_ride/model/trip/wrapup/payment.dart';

abstract final class PaymentMethodIcon {
  static IconData of(PaymentMethod? method, {GroupKind? groupKind}) => switch (method) {
    null => Icons.receipt_long_outlined,
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.card => Icons.credit_card_rounded,
    PaymentMethod.wallet => switch (groupKind) {
      GroupKind.business => Icons.apartment_rounded,
      GroupKind.family => Icons.family_restroom_rounded,
      null => Icons.account_balance_wallet_outlined,
    },
  };
}
