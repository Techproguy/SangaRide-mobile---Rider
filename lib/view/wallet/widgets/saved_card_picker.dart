import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
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
            subtitle: WalletCopy.cardExpires(card.expiry),
            isSelected: card.id == selectedId,
            onTap: () => onSelect(card.id),
          ),
        SangaOptionCard(
          leading: const SangaIconBadge(child: Icon(Icons.add_card_rounded)),
          title: WalletCopy.useNewCard,
          subtitle: WalletCopy.canSaveForNextTime,
          isSelected: selectedId == null,
          onTap: () => onSelect(null),
        ),
      ],
    );
  }
}
