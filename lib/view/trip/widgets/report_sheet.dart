import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key, required this.isReporting, required this.onReport, required this.onDismiss});

  final bool isReporting;
  final ValueChanged<Set<TripIssue>> onReport;
  final VoidCallback onDismiss;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final Set<TripIssue> _selected = {};

  void _toggle(TripIssue issue, bool isChecked) {
    setState(() => isChecked ? _selected.add(issue) : _selected.remove(issue));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Report an issue', style: SangaTextStyles.statusTitle)),
              SangaCircleButton.close(onPressed: widget.onDismiss),
            ],
          ),
          const SizedBox(height: SangaSpacing.md),
          for (final issue in TripIssue.values)
            SangaCheckRow.text(
              isChecked: _selected.contains(issue),
              onChanged: (isChecked) => _toggle(issue, isChecked),
              text: issue.label,
            ),
          const SizedBox(height: SangaSpacing.lg),
          SangaButton.danger(
            label: 'Report and cancel',
            isLoading: widget.isReporting,
            onPressed: _selected.isEmpty ? null : () => widget.onReport({..._selected}),
          ),
          const SizedBox(height: SangaSpacing.sm),
          SangaButton.muted(label: 'I’ll check again', onPressed: widget.isReporting ? null : widget.onDismiss),
        ],
      ),
    );
  }
}
