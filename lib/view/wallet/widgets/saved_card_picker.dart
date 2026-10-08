import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SavedCardPicker extends StatelessWidget {
  const SavedCardPicker({super.key, required this.cards, required this.selectedId, required this.onSelect});

  final List<SavedCard> cards;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: SangaSpacing.sm,
      children: [
        for (final card in cards)
          SangaOptionCard(
            leading: const SangaIconBadge(child: Icon(Icons.credit_card_rounded)),
            title: card.title,
            subtitle: 'Expires ${card.expiry}',
            isSelected: card.id == selectedId,
            onTap: () => onSelect(card.id),
          ),
        SangaOptionCard(
          leading: const SangaIconBadge(child: Icon(Icons.add_card_rounded)),
          title: 'Use a new card',
          subtitle: 'We can save it for next time',
          isSelected: selectedId == null,
          onTap: () => onSelect(null),
        ),
      ],
    );
  }
}
