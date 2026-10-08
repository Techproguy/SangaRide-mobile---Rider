import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TransactionFilterChips extends StatelessWidget {
  const TransactionFilterChips({super.key, required this.selected, required this.onSelected});

  final TransactionFilter selected;
  final ValueChanged<TransactionFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.gutter, vertical: SangaSpacing.sm),
      child: Row(
        spacing: SangaSpacing.sm,
        children: [
          for (final filter in TransactionFilter.values)
            SangaChoiceChip(label: filter.label, isSelected: filter == selected, onSelected: (_) => onSelected(filter)),
        ],
      ),
    );
  }
}
