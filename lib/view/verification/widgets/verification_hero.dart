import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/verification/verification_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerificationHero extends StatelessWidget {
  const VerificationHero({super.key, required this.status, required this.copy, this.submittedLine});

  static const double _badge = 84;

  final VerificationStatus status;
  final VerificationHeroCopy copy;
  final String? submittedLine;

  Widget get _icon => switch (status) {
    VerificationStatus.pending => const SangaActivityIndicator(size: 52),
    VerificationStatus.verified => const Icon(Icons.verified_rounded, size: 44, color: SangaColors.success),
    VerificationStatus.rejected || VerificationStatus.actionNeeded => const Icon(
      Icons.error_outline_rounded,
      size: 44,
      color: SangaColors.dangerStrong,
    ),
    VerificationStatus.unverified => const Icon(Icons.shield_outlined, size: 44, color: SangaColors.primary),
  };

  Color get _wash => switch (status) {
    VerificationStatus.verified => SangaColors.successSoft,
    VerificationStatus.rejected || VerificationStatus.actionNeeded => SangaColors.dangerSoft,
    VerificationStatus.pending || VerificationStatus.unverified => SangaColors.chipBlue,
  };

  @override
  Widget build(BuildContext context) {
    final submitted = submittedLine;
    return SangaHandoff(
      value: status,
      child: Column(
        spacing: SangaSpacing.xs,
        children: [
          Container(
            width: _badge,
            height: _badge,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _wash, shape: BoxShape.circle),
            child: _icon,
          ),
          const SizedBox(height: SangaSpacing.xs),
          Text(copy.title, textAlign: TextAlign.center, style: SangaTextStyles.title),
          Text(copy.message, textAlign: TextAlign.center, style: SangaTextStyles.body),
          if (submitted != null) Text(submitted, textAlign: TextAlign.center, style: SangaTextStyles.caption),
        ],
      ),
    );
  }
}
