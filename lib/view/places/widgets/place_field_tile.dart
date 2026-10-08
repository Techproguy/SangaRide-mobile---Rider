import 'package:flutter/material.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PlaceFieldTile extends StatelessWidget {
  const PlaceFieldTile({
    super.key,
    required this.placeholder,
    required this.onTap,
    this.place,
    this.hint,
    this.pinColor = SangaColors.primary,
  });

  static const double _minHeight = 58;
  static const double _pinSize = 22;

  final String placeholder;
  final String? hint;
  final Place? place;
  final Color pinColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = place;
    return Material(
      color: SangaColors.fill,
      shape: const RoundedRectangleBorder(borderRadius: SangaRadii.field),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.sm),
            child: Row(
              spacing: SangaSpacing.sm,
              children: [
                Icon(Icons.location_on_rounded, size: _pinSize, color: pinColor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: SangaSpacing.xxs,
                    children: [
                      Text(
                        chosen?.name ?? placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SangaTextStyles.input.copyWith(
                          color: chosen == null ? SangaColors.textPlaceholder : null,
                        ),
                      ),
                      if (chosen != null || hint != null)
                        Text(
                          chosen?.address ?? hint!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SangaTextStyles.tileSubtitle,
                        ),
                    ],
                  ),
                ),
                if (chosen != null) SangaListRow.chevron,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
