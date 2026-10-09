import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/trip/cancel/widgets/cancel_copy.dart';
import 'package:sanga_ride/view/trip/cancel/widgets/cancel_reason_row.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CancelReasonsView extends StatefulWidget {
  const CancelReasonsView({
    super.key,
    required this.copy,
    required this.reasons,
    required this.reason,
    required this.note,
    required this.canContinue,
    required this.isLoading,
    required this.onSelect,
    required this.onNote,
    required this.onContinue,
  });

  final CancelCopy copy;
  final List<CancelReason> reasons;
  final CancelReason? reason;
  final String note;
  final bool canContinue;
  final bool isLoading;
  final ValueChanged<CancelReason> onSelect;
  final ValueChanged<String> onNote;
  final VoidCallback onContinue;

  @override
  State<CancelReasonsView> createState() => _CancelReasonsViewState();
}

class _CancelReasonsViewState extends State<CancelReasonsView> {
  late final _note = TextEditingController(text: widget.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reason = widget.reason;
    return SangaPageLayout(
      title: widget.copy.title,
      footer: SangaButton.primary(
        label: 'Continue',
        isLoading: widget.isLoading,
        onPressed: widget.canContinue ? widget.onContinue : null,
      ),
      children: [
        const SangaSectionHeader('Why are you cancelling?'),
        const SizedBox(height: SangaSpacing.sm),
        SangaListGroup(
          children: [
            for (final option in widget.reasons)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md),
                child: CancelReasonRow(
                  reason: option,
                  isSelected: option == reason,
                  onTap: () => widget.onSelect(option),
                ),
              ),
          ],
        ),
        if (reason != null && reason.needsNote) ...[
          const SizedBox(height: SangaSpacing.md),
          SangaTextArea(
            label: 'Tell us what happened',
            controller: _note,
            hintText: 'A few words is plenty',
            maxLength: CancelReason.maxNoteLength,
            onChanged: widget.onNote,
          ).animate().fadeIn(duration: SangaMotion.quick, curve: SangaMotion.fadeCurve),
        ],
      ],
    );
  }
}
