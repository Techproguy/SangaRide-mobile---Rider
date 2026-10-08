import 'package:flutter/material.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride/view/places/widgets/saved_place_icon.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SavedPlacesList extends StatelessWidget {
  const SavedPlacesList({
    super.key,
    required this.book,
    required this.busy,
    required this.onSet,
    required this.onEdit,
    required this.onRemove,
  });

  static const double _busyOpacity = 0.4;
  static const double _target = 44;

  final SavedPlaceBook book;
  final Set<String> busy;
  final ValueChanged<SavedPlaceKind> onSet;
  final ValueChanged<SavedPlace> onEdit;
  final ValueChanged<SavedPlace> onRemove;

  @override
  Widget build(BuildContext context) {
    return SangaListGroup(
      children: [
        for (final kind in SavedPlaceKind.values.where((kind) => kind.isSlot)) _slot(kind),
        for (final saved in book.others) _saved(saved, onTap: () => onEdit(saved)),
      ],
    );
  }

  Widget _slot(SavedPlaceKind kind) {
    final saved = book.of(kind);
    if (saved == null) {
      return SangaListRow.saved(
        icon: kind.icon,
        title: 'Add ${kind.label.toLowerCase()}',
        subtitle: 'Save it once, ride there in one tap',
        trailing: const Icon(Icons.add_rounded, size: 22, color: SangaColors.primary),
        onTap: busy.contains(kind.code) ? null : () => onSet(kind),
      );
    }
    return _saved(saved, onTap: () => onSet(kind));
  }

  Widget _saved(SavedPlace saved, {required VoidCallback onTap}) {
    final isBusy = busy.contains(saved.id);
    return Opacity(
      opacity: isBusy ? _busyOpacity : 1,
      child: SangaListRow.saved(
        icon: saved.kind.icon,
        title: saved.label,
        subtitle: saved.place.address,
        trailing: IconButton(
          tooltip: 'Remove ${saved.label}',
          onPressed: isBusy ? null : () => onRemove(saved),
          constraints: const BoxConstraints.tightFor(width: _target, height: _target),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: SangaColors.primary),
        ),
        onTap: isBusy ? null : onTap,
      ),
    );
  }
}
