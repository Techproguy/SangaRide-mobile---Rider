import 'package:flutter/material.dart';
import 'package:sanga_ride/core/format/clock_formats.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryProofRows extends StatelessWidget {
  const DeliveryProofRows({super.key, required this.proof, required this.dropoff, required this.recipient});

  final DeliveryProof proof;
  final TripPlace dropoff;
  final DeliveryRecipient recipient;

  @override
  Widget build(BuildContext context) {
    final isVerified = proof.isAtDropoff(dropoff.position);
    return Column(
      spacing: SangaSpacing.md,
      children: [
        _ProofRow(
          icon: Icons.photo_camera_outlined,
          tone: _ProofTone.green,
          title: proof.photoUrl == null ? 'No photo taken' : 'Photo captured',
          subtitle: '${ClockFormats.time(proof.at)} · ${ClockFormats.weekdayDate(proof.at)}',
        ),
        _ProofRow(
          icon: Icons.location_on_outlined,
          tone: _ProofTone.blue,
          title: isVerified ? 'Location verified' : 'Location recorded',
          subtitle: isVerified ? dropoff.name : 'A little way from ${dropoff.name}',
        ),
        _ProofRow(
          icon: Icons.person_outline_rounded,
          tone: _ProofTone.grey,
          title: 'Recipient',
          subtitle: recipient.name,
          trailing: proof.recipientConfirmed
              ? const SangaTag.success(label: 'Confirmed')
              : const SangaTag.warning(label: 'Not confirmed'),
        ),
      ],
    );
  }
}

enum _ProofTone { green, blue, grey }

class _ProofRow extends StatelessWidget {
  const _ProofRow({required this.icon, required this.tone, required this.title, required this.subtitle, this.trailing});

  static const double _badge = 40;

  final IconData icon;
  final _ProofTone tone;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final (color, wash) = switch (tone) {
      _ProofTone.green => (SangaColors.success, SangaColors.successSoft),
      _ProofTone.blue => (SangaColors.primary, SangaColors.primaryTint),
      _ProofTone.grey => (SangaColors.textMid, SangaColors.cardMuted),
    };
    return Row(
      spacing: SangaSpacing.md,
      children: [
        Container(
          width: _badge,
          height: _badge,
          decoration: BoxDecoration(color: wash, borderRadius: SangaRadii.field),
          child: Icon(icon, size: 22, color: color),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.xxs,
            children: [
              Text(title, style: SangaTextStyles.cardTitle),
              Text(subtitle, style: SangaTextStyles.cardSubtitle),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
