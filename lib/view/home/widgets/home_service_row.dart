import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HomeService {
  const HomeService({
    required this.image,
    required this.label,
    required this.onTap,
    this.imageInset = SangaSpacing.xs,
    this.isSelected = false,
  });

  final ImageProvider image;
  final String label;
  final VoidCallback onTap;
  final double imageInset;
  final bool isSelected;
}

class HomeServiceRow extends StatelessWidget {
  const HomeServiceRow({super.key, required this.services});

  static const int _perRow = 4;

  final List<HomeService> services;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visible = services.length < _perRow ? services.length : _perRow;
        final gaps = SangaSpacing.sm * (visible - 1);
        final tileWidth = (constraints.maxWidth - gaps) / visible;
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SangaSpacing.sm,
          children: [
            for (final service in services)
              SizedBox(
                width: tileWidth,
                child: _HomeServiceTile(service: service),
              ),
          ],
        );
        if (services.length <= _perRow) return row;
        return SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
      },
    );
  }
}

class _HomeServiceTile extends StatelessWidget {
  const _HomeServiceTile({required this.service});

  final HomeService service;

  @override
  Widget build(BuildContext context) {
    final isSelected = service.isSelected;
    return Semantics(
      button: true,
      selected: isSelected,
      label: service.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: service.onTap,
        child: Column(
          spacing: SangaSpacing.xs,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: AnimatedContainer(
                duration: SangaMotion.quick,
                padding: EdgeInsets.all(service.imageInset),
                decoration: BoxDecoration(
                  color: isSelected ? SangaColors.primaryTint : SangaColors.tileFill,
                  borderRadius: SangaRadii.digit,
                  border: Border.all(color: isSelected ? SangaColors.primary : SangaColors.textMid, width: 0.5),
                ),
                child: Image(image: service.image, fit: BoxFit.contain),
              ),
            ),
            Text(
              service.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SangaTextStyles.tileCaption.copyWith(color: isSelected ? SangaColors.primary : null),
            ),
          ],
        ),
      ),
    );
  }
}
