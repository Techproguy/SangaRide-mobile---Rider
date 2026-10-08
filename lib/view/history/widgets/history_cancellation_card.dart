import 'package:flutter/material.dart';
import 'package:sanga_ride/model/history/history_detail.dart';
import 'package:sanga_ride/view/history/widgets/history_format.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryCancellationCard extends StatelessWidget {
  const HistoryCancellationCard({super.key, required this.detail, required this.cancellation});

  final HistoryDetail detail;
  final HistoryCancellation cancellation;

  @override
  Widget build(BuildContext context) {
    return SangaDetailList(
      title: 'Cancellation',
      rows: [
        SangaDetailRow(icon: Icons.person_outline_rounded, label: 'Cancelled by', value: cancellation.by.label),
        SangaDetailRow(icon: Icons.chat_bubble_outline_rounded, label: 'Reason', value: cancellation.reason),
        SangaDetailRow(
          icon: Icons.payments_outlined,
          label: 'Fee',
          value: cancellation.hasFee ? SangaMoney.naira(cancellation.fee) : 'No fee',
        ),
        SangaDetailRow(icon: Icons.event_rounded, label: 'Date', value: formatHistoryDate(detail.occurredAt)),
        SangaDetailRow(icon: Icons.tag_rounded, label: 'Reference', value: detail.reference),
      ],
    );
  }
}
