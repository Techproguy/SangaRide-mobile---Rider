import 'package:sanga_ride/model/location/place.dart';

enum SavedPlaceKind {
  home('home', 'Home'),
  work('work', 'Work'),
  other('other', 'Other');

  const SavedPlaceKind(this.code, this.label);

  final String code;
  final String label;

  bool get isSlot => this != other;

  static SavedPlaceKind fromCode(String code) => values.firstWhere(
    (kind) => kind.code == code,
    orElse: () => throw FormatException('Unknown saved place kind: $code'),
  );
}

class SavedPlace {
  const SavedPlace({required this.id, required this.kind, required this.label, required this.place});

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
    id: json['id'] as String,
    kind: SavedPlaceKind.fromCode(json['kind'] as String),
    label: json['label'] as String,
    place: Place.fromJson(Map<String, dynamic>.from(json['place'] as Map)),
  );

  final String id;
  final SavedPlaceKind kind;
  final String label;
  final Place place;

  SavedPlace copyWith({String? label, Place? place}) =>
      SavedPlace(id: id, kind: kind, label: label ?? this.label, place: place ?? this.place);
}

class SavedPlaceBook {
  const SavedPlaceBook({required this.places, required this.maxOthers});

  factory SavedPlaceBook.fromJson(Map<String, dynamic> json) => SavedPlaceBook(
    places: [for (final place in json['places'] as List) SavedPlace.fromJson(Map<String, dynamic>.from(place as Map))],
    maxOthers: (json['maxOthers'] as num).toInt(),
  );

  static const int maxLabelLength = 24;

  final List<SavedPlace> places;
  final int maxOthers;

  SavedPlace? of(SavedPlaceKind kind) {
    for (final saved in places) {
      if (saved.kind == kind) return saved;
    }
    return null;
  }

  SavedPlace? get home => of(SavedPlaceKind.home);

  SavedPlace? get work => of(SavedPlaceKind.work);

  List<SavedPlace> get others => [
    for (final saved in places)
      if (!saved.kind.isSlot) saved,
  ];

  bool get canAddOther => others.length < maxOthers;

  bool isSaved(Place place) => places.any((saved) => saved.place.isSameAs(place));

  bool labelTaken(String label, {String? exceptId}) {
    final needle = label.trim().toLowerCase();
    final reserved = SavedPlaceKind.values.where((kind) => kind.isSlot).map((kind) => kind.label.toLowerCase());
    if (reserved.contains(needle)) return true;
    return others.any((saved) => saved.id != exceptId && saved.label.toLowerCase() == needle);
  }

  static bool _replaces(SavedPlace existing, SavedPlace saved) =>
      existing.id == saved.id || (saved.kind.isSlot && existing.kind == saved.kind);

  SavedPlaceBook withSaved(SavedPlace saved) {
    final isKnown = places.any((existing) => _replaces(existing, saved));
    return SavedPlaceBook(
      places: isKnown
          ? [for (final existing in places) _replaces(existing, saved) ? saved : existing]
          : [...places, saved],
      maxOthers: maxOthers,
    );
  }

  SavedPlaceBook without(String id) => SavedPlaceBook(
    places: [
      for (final saved in places)
        if (saved.id != id) saved,
    ],
    maxOthers: maxOthers,
  );
}

enum SavedPlaceProblem {
  duplicateLabel('duplicate_label', 'You already have a place with that name. Try another.'),
  limitReached('limit_reached', 'You’ve saved as many places as you can. Remove one to add another.'),
  invalidLabel('invalid_label', 'Give this place a short name.'),
  invalidPlace('invalid_place', 'We couldn’t use that location. Pick another one.'),
  notFound('not_found', 'We can’t find that place. It may already be gone.'),
  unknown('unknown', 'We couldn’t do that. Give it another go.');

  const SavedPlaceProblem(this.code, this.message);

  final String code;
  final String message;

  static SavedPlaceProblem fromCode(String? code) =>
      values.firstWhere((problem) => problem.code == code, orElse: () => unknown);
}

sealed class SavedPlacesState {
  const SavedPlacesState();
}

final class SavedPlacesLoading extends SavedPlacesState {
  const SavedPlacesLoading();
}

final class SavedPlacesFailed extends SavedPlacesState {
  const SavedPlacesFailed();
}

final class SavedPlacesLoaded extends SavedPlacesState {
  const SavedPlacesLoaded(this.book, {this.busy = const {}});

  static const String newPlaceKey = 'new';

  final SavedPlaceBook book;
  final Set<String> busy;

  bool isBusy(String key) => busy.contains(key);

  SavedPlacesLoaded copyWith({SavedPlaceBook? book, Set<String>? busy}) =>
      SavedPlacesLoaded(book ?? this.book, busy: busy ?? this.busy);
}
