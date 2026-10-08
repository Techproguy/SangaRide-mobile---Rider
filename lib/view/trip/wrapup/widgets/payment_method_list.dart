import 'package:flutter/material.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PaymentMethodList extends StatelessWidget {
  const PaymentMethodList({
    super.key,
    required this.methods,
    required this.selected,
    required this.lastMethod,
    required this.onSelect,
  });

  final List<PaymentMethod> methods;
  final PaymentMethod selected;
  final PaymentMethod? lastMethod;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.sm,
      children: [
        for (final method in methods)
          SangaOptionCard(
            leading: SangaIconBadge(child: Icon(_iconOf(method))),
            title: method.label,
            subtitle: method == lastMethod ? 'You paid this way last time' : method.subtitle,
            isSelected: method == selected,
            onTap: () => onSelect(method),
          ),
      ],
    );
  }

  IconData _iconOf(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.card => Icons.credit_card_rounded,
  };
}
