import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/places_endpoints.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class SavedPlacesController extends GetxController {
  final _api = Get.find<ApiService>();

  IdempotencyKey? _createKey;
  String? _createSignature;

  final Rx<SavedPlacesState> _state = Rx<SavedPlacesState>(const SavedPlacesLoading());
  int _epoch = 0;

  Rx<SavedPlacesState> get stateRx => _state;

  SavedPlacesState get state => _state.value;

  SavedPlaceBook? get book => switch (state) {
    SavedPlacesLoaded(:final book) => book,
    SavedPlacesLoading() || SavedPlacesFailed() => null,
  };

  Place? get home => book?.home?.place;

  Place? get work => book?.work?.place;

  List<SavedPlace> get others => book?.others ?? const [];

  bool isSaved(Place place) => book?.isSaved(place) ?? false;

  Future<bool> load() async {
    final epoch = ++_epoch;
    if (state is! SavedPlacesLoaded) _state.value = const SavedPlacesLoading();
    try {
      final response = await _api.get(PlacesEndpoints.saved, suppressErrorToast: true);
      if (epoch != _epoch) return state is SavedPlacesLoaded;
      final current = state;
      _state.value = SavedPlacesLoaded(
        SavedPlaceBook.fromJson((response.data as Map)['data']),
        busy: current is SavedPlacesLoaded ? current.busy : const {},
      );
      return true;
    } catch (e) {
      log('load saved places failed: $e');
      if (epoch == _epoch && state is! SavedPlacesLoaded) {
        _state.value = SavedPlacesFailed(problem: RideLoadProblem.of(e));
      }
      return state is SavedPlacesLoaded;
    }
  }

  Future<bool> ensureLoaded() async => state is SavedPlacesLoaded || await load();

  Future<SavedPlaceProblem?> save({
    required SavedPlaceKind kind,
    required String label,
    required Place place,
    String? id,
  }) {
    final key = id ?? (kind.isSlot ? kind.code : SavedPlacesLoaded.newPlaceKey);
    return _mutate(key, () async {
      final body = {'label': label.trim(), 'place': place.toJson(), if (id == null) 'kind': kind.code};
      final response = id == null
          ? await _api.post(PlacesEndpoints.saved, data: body, key: _keyFor(body), suppressErrorToast: true)
          : await _api.patch(PlacesEndpoints.savedOf(id), data: body, suppressErrorToast: true);
      final saved = SavedPlace.fromJson(JsonReader.of((response.data as Map)['data']));
      _createKey = null;
      return (SavedPlaceBook book) => book.withSaved(saved);
    });
  }

  Future<SavedPlaceProblem?> remove(SavedPlace saved) => _mutate(saved.id, () async {
    await _api.delete(PlacesEndpoints.savedOf(saved.id), suppressErrorToast: true);
    return (SavedPlaceBook book) => book.without(saved.id);
  });

  Future<SavedPlaceProblem?> _mutate(
    String key,
    Future<SavedPlaceBook Function(SavedPlaceBook book)> Function() request,
  ) async {
    final current = state;
    if (current is! SavedPlacesLoaded || current.isBusy(key)) return null;
    _epoch++;
    _state.value = current.copyWith(busy: {...current.busy, key});
    try {
      final update = await request();
      _settle(key, update: update);
      return null;
    } catch (e) {
      log('saved places change failed: $e');
      final problem = SavedPlaceProblem.of(e);
      _settle(key);
      if (problem == SavedPlaceProblem.notFound || (e is ApiException && e.outcomeUnknown)) unawaited(load());
      return problem;
    }
  }

  IdempotencyKey _keyFor(Map<String, dynamic> body) {
    final signature = body.toString();
    if (_createKey == null || _createSignature != signature) {
      _createKey = IdempotencyKey.newFor('save-place');
      _createSignature = signature;
    }
    return _createKey!;
  }

  void _settle(String key, {SavedPlaceBook Function(SavedPlaceBook book)? update}) {
    final current = state;
    if (current is! SavedPlacesLoaded) return;
    _state.value = current.copyWith(book: update?.call(current.book), busy: {...current.busy}..remove(key));
  }
}
