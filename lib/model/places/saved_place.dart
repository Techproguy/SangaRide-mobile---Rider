import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum SavedPlaceKind {
  home('home', 'Home'),
  work('work', 'Work'),
  other('other', 'Other');

  const SavedPlaceKind(this.code, this.label);

  final String code;
  final String label;

  bool get isSlot => this != other;

  static SavedPlaceKind fromCode(String? code) => enumByCode(values, code, (kind) => kind.code, other);
}

class SavedPlace {
  const SavedPlace({required this.id, required this.kind, required this.label, required this.place});

  factory SavedPlace.fromJson(JsonReader json) => SavedPlace(
    id: json.str('id'),
    kind: SavedPlaceKind.fromCode(json.strOrNull('kind')),
    label: json.strOr('label', ''),
    place: Place.fromJson(json.object('place').raw),
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

  factory SavedPlaceBook.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return SavedPlaceBook(places: json.listOf('places', SavedPlace.fromJson), maxOthers: json.intOr('maxOthers', 5));
  }

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
  notFound(ServerCode.notFound, 'We can’t find that place. It may already be gone.'),
  connection('connection', CommonCopy.offline),
  unknown('unknown', CommonCopy.serverTrouble);

  const SavedPlaceProblem(this.code, this.message);

  final String code;
  final String message;

  static SavedPlaceProblem fromCode(String? code) => enumByCode(values, code, (problem) => problem.code, unknown);

  static SavedPlaceProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => fromCode(code),
    _ => unknown,
  };
}

sealed class SavedPlacesState {
  const SavedPlacesState();
}

final class SavedPlacesLoading extends SavedPlacesState {
  const SavedPlacesLoading();
}

final class SavedPlacesFailed extends SavedPlacesState {
  const SavedPlacesFailed({this.problem = RideLoadProblem.connection});

  final RideLoadProblem problem;
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
