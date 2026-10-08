import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RideOptionLanguageRow extends StatelessWidget {
  const RideOptionLanguageRow({
    super.key,
    required this.leading,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  static const double _menuWidth = 160;
  static const double _optionHeight = 44;

  final Widget leading;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SangaSpacing.md),
      child: Row(
        spacing: SangaSpacing.md,
        children: [
          leading,
          Expanded(child: Text(title, style: SangaTextStyles.cardTitle)),
          MenuAnchor(
            alignmentOffset: const Offset(0, SangaSpacing.xs),
            style: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll(SangaColors.fill),
              elevation: WidgetStatePropertyAll(6),
              shadowColor: WidgetStatePropertyAll(SangaColors.cardShadow),
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              minimumSize: WidgetStatePropertyAll(Size(_menuWidth, 0)),
              maximumSize: WidgetStatePropertyAll(Size(_menuWidth, _optionHeight * 6.5)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: SangaRadii.digit)),
            ),
            menuChildren: [
              for (final (index, option) in options.indexed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: index == 0 ? null : const Border(top: BorderSide(color: SangaColors.divider)),
                  ),
                  child: MenuItemButton(
                    onPressed: () => onChanged(option),
                    style: ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(Size(_menuWidth, _optionHeight)),
                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: SangaSpacing.md)),
                      backgroundColor: WidgetStatePropertyAll(
                        option == value ? SangaColors.primaryWash : Colors.transparent,
                      ),
                    ),
                    child: Text(option, style: SangaTextStyles.input),
                  ),
                ),
            ],
            builder: (context, menu, _) => Semantics(
              button: true,
              expanded: menu.isOpen,
              label: '$title, $value',
              child: InkWell(
                borderRadius: SangaRadii.digit,
                onTap: () => menu.isOpen ? menu.close() : menu.open(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.sm, vertical: SangaSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: SangaSpacing.xxs,
                    children: [
                      Text(value, style: SangaTextStyles.cardValue),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: SangaColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
