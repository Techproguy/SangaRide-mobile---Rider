import 'package:flutter/material.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride/view/wallet/wallet_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ResumeTopUpCard extends StatelessWidget {
  const ResumeTopUpCard({super.key, required this.saved, required this.onTap});

  final SavedTopUp saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SangaListGroup(
      children: [
        SangaListRow(
          leading: const SangaIconBadge(size: 40, child: Icon(Icons.hourglass_top_rounded)),
          title: WalletCopy.resumeTitle(saved.amount),
          subtitle: WalletCopy.resumeSubtitle(saved.method),
          titleMaxLines: 2,
          onTap: onTap,
        ),
      ],
    );
  }
}
