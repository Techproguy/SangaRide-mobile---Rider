import 'package:flutter/material.dart';
import 'package:sanga_ride/core/format/time_format.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/support_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class TicketRow extends StatelessWidget {
  const TicketRow({super.key, required this.ticket, required this.onTap});

  final TicketSummary ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.sm + 2),
        child: Row(
          spacing: SangaSpacing.sm,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SangaSpacing.xxs,
                children: [
                  Text(ticket.typeLabel, style: SangaTextStyles.cardTitle),
                  Text(
                    '${ticket.reference} · ${TimeFormat.ago(ticket.createdAt)}',
                    style: SangaTextStyles.tileSubtitle,
                  ),
                ],
              ),
            ),
            SupportCopy.statusTagOf(ticket.status),
            SangaListRow.chevron,
          ],
        ),
      ),
    );
  }
}
