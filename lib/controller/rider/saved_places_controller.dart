import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart' show Options;
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/places_endpoints.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/places/saved_place.dart';

class SavedPlacesController extends GetxController {
  static final Options _quiet = Options(extra: {'suppressErrorToast': true});

  final _api = Get.find<ApiService>();

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
      final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
      final current = state;
      _state.value = SavedPlacesLoaded(
        SavedPlaceBook.fromJson(data),
        busy: current is SavedPlacesLoaded ? current.busy : const {},
      );
      return true;
    } catch (e) {
      log('load saved places failed: $e');
      if (epoch == _epoch && state is! SavedPlacesLoaded) _state.value = const SavedPlacesFailed();
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
          ? await _api.post(PlacesEndpoints.saved, data: body, suppressErrorToast: true)
          : await _api.patch(PlacesEndpoints.savedOf(id), data: body, options: _quiet);
      final data = Map<String, dynamic>.from((response.data as Map)['data'] as Map);
      final saved = SavedPlace.fromJson(data);
      return (SavedPlaceBook book) => book.withSaved(saved);
    });
  }

  Future<SavedPlaceProblem?> remove(SavedPlace saved) => _mutate(saved.id, () async {
    await _api.delete(PlacesEndpoints.savedOf(saved.id), options: _quiet);
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
    } on ApiException catch (e) {
      log('saved places change failed: ${e.code}');
      final problem = SavedPlaceProblem.fromCode(e.code);
      _settle(key);
      if (problem == SavedPlaceProblem.notFound) unawaited(load());
      return problem;
    } catch (e) {
      log('saved places change failed: $e');
      _settle(key);
      return SavedPlaceProblem.unknown;
    }
  }

  void _settle(String key, {SavedPlaceBook Function(SavedPlaceBook book)? update}) {
    final current = state;
    if (current is! SavedPlacesLoaded) return;
    _state.value = current.copyWith(book: update?.call(current.book), busy: {...current.busy}..remove(key));
  }
}
