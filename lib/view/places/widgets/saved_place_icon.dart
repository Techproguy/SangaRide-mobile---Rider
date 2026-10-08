import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

extension SavedPlaceKindIcon on SavedPlaceKind {
  String get icon => switch (this) {
    SavedPlaceKind.home => SangaAssets.placeHome,
    SavedPlaceKind.work => SangaAssets.placeWork,
    SavedPlaceKind.other => SangaAssets.placeSaved,
  };
}
