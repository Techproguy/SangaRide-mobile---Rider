import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PackageSummary extends StatelessWidget {
  const PackageSummary({
    super.key,
    required this.photo,
    required this.name,
    required this.description,
    required this.facts,
    required this.valueLabel,
    required this.photoLabel,
    required this.onEditPhoto,
    required this.onEditValue,
  });

  static const double _thumb = 64;

  final ImageProvider? photo;
  final String name;
  final String description;
  final String facts;
  final String valueLabel;
  final String photoLabel;
  final VoidCallback onEditPhoto;
  final VoidCallback onEditValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.xs),
      child: Column(
        spacing: SangaSpacing.sm,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.md,
            children: [
              _Thumb(photo: photo),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: SangaSpacing.xxs,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SangaTextStyles.cardTitle),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SangaTextStyles.cardSubtitle,
                    ),
                    if (facts.isNotEmpty)
                      Text(facts, style: SangaTextStyles.cardSubtitle.copyWith(color: SangaColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          _Line(label: 'Photo', value: photoLabel, onTap: onEditPhoto),
          _Line(label: 'Declared value', value: valueLabel, onTap: onEditValue),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo});

  final ImageProvider? photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PackageSummary._thumb,
      height: PackageSummary._thumb,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: SangaColors.fill, borderRadius: SangaRadii.digit),
      child: photo == null
          ? const Icon(Icons.inventory_2_outlined, color: SangaColors.textMuted)
          : Image(
              image: photo!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.inventory_2_outlined, color: SangaColors.textMuted),
            ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: SangaRadii.digit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SangaSpacing.xs),
        child: Row(
          spacing: SangaSpacing.sm,
          children: [
            Text(label, style: SangaTextStyles.cardSubtitle.copyWith(color: SangaColors.textMuted)),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: SangaTextStyles.cardSubtitle.copyWith(
                  color: SangaColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SangaListRow.chevron,
          ],
        ),
      ),
    );
  }
}
