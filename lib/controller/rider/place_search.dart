import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/core/services/places_service.dart';
import 'package:sanga_ride/model/models.dart';

enum PlaceSearchStatus { idle, searching, results, empty, failed }

class PlaceSearch extends ChangeNotifier {
  PlaceSearch({this.origin});

  static const Duration _debounce = Duration(milliseconds: 300);

  final PlacesService _places = PlacesService();

  LatLng? origin;
  String _query = '';
  List<PlaceAutocomplete> _results = const [];
  PlaceSearchStatus _status = PlaceSearchStatus.idle;
  String? _openingId;
  Timer? _timer;
  int _request = 0;
  String _sessionToken = _newSessionToken();

  String get query => _query;

  List<PlaceAutocomplete> get results => _results;

  PlaceSearchStatus get status => _status;

  bool get isIdle => _status == PlaceSearchStatus.idle;

  bool isOpening(PlaceAutocomplete prediction) => _openingId == prediction.placeId;

  static String _newSessionToken() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  void search(String text) {
    _timer?.cancel();
    _request++;
    _query = text.trim();
    if (_query.isEmpty) {
      _results = const [];
      _status = PlaceSearchStatus.idle;
    } else {
      _status = PlaceSearchStatus.searching;
      _timer = Timer(_debounce, _run);
    }
    notifyListeners();
  }

  void retry() => search(_query);

  void clear() => search('');

  Future<void> _run() async {
    final request = _request;
    try {
      final results = await _places.getAutocompletePredictions(_query, sessionToken: _sessionToken, origin: origin);
      if (request != _request) return;
      _results = results;
      _status = results.isEmpty ? PlaceSearchStatus.empty : PlaceSearchStatus.results;
    } catch (e) {
      log('place search failed: $e');
      if (request != _request) return;
      _results = const [];
      _status = PlaceSearchStatus.failed;
    }
    notifyListeners();
  }

  Future<Place?> open(PlaceAutocomplete prediction) async {
    if (_openingId != null) return null;
    _openingId = prediction.placeId;
    notifyListeners();
    try {
      final place = await _places.getPlaceDetails(prediction.placeId, sessionToken: _sessionToken);
      if (place?.coordinates == null) return null;
      _sessionToken = _newSessionToken();
      return place;
    } catch (e) {
      log('place details failed: $e');
      return null;
    } finally {
      _openingId = null;
      notifyListeners();
    }
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
