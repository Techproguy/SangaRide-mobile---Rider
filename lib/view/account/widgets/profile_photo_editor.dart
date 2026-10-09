import 'package:flutter/material.dart';
import 'package:sanga_ride/view/account/account_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ProfilePhotoEditor extends StatelessWidget {
  const ProfilePhotoEditor({
    super.key,
    required this.name,
    required this.image,
    required this.isUploading,
    required this.onEdit,
  });

  static const double _size = 96;
  static const double _badge = 32;

  final String name;
  final ImageProvider? image;
  final bool isUploading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size + _badge / 2,
      height: _size + _badge / 4,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SangaAvatar(name: name, size: _size, image: image, onTap: onEdit),
                if (isUploading)
                  const SizedBox.square(
                    dimension: _size,
                    child: DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: SangaColors.scrim),
                      child: Center(child: SangaActivityIndicator(size: 24, color: SangaColors.onPrimary)),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Semantics(
              button: true,
              label: AccountCopy.changePhoto,
              child: SizedBox.square(
                dimension: _badge,
                child: Material(
                  color: SangaColors.primary,
                  shape: const CircleBorder(side: BorderSide(color: SangaColors.surface, width: 2)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: isUploading ? null : onEdit,
                    child: const Icon(Icons.edit_rounded, size: 16, color: SangaColors.onPrimary),
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
