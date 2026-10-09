import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/controller/rider/place_search.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/widgets/place_search_results.dart';
import 'package:sanga_ride/view/ride/widgets/place_suggestions.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PlaceSearchSheet extends StatefulWidget {
  const PlaceSearchSheet({super.key, required this.kind, required this.hintText, required this.onPick, this.origin});

  final SangaStopKind kind;
  final String hintText;
  final LatLng? origin;
  final String? Function(Place place) onPick;

  static Future<Place?> show(
    BuildContext context, {
    required SangaStopKind kind,
    required String hintText,
    required String? Function(Place place) onPick,
    LatLng? origin,
  }) {
    return showSangaSheet<Place>(
      context: context,
      padding: const EdgeInsets.fromLTRB(SangaSpacing.md, SangaSpacing.md, SangaSpacing.md, 0),
      builder: (context) => PlaceSearchSheet(kind: kind, hintText: hintText, origin: origin, onPick: onPick),
    );
  }

  @override
  State<PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<PlaceSearchSheet> {
  static const double _heightFactor = 0.62;
  static const double _topClearance = 72;

  final _query = TextEditingController();
  late final _search = PlaceSearch(origin: widget.origin);

  @override
  void dispose() {
    _search.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _open(PlaceAutocomplete prediction) async {
    final place = await _search.open(prediction);
    if (!mounted) return;
    if (place == null) {
      return SangaToast.show(CommonCopy.placeLoadFailed, tone: SangaToastTone.error);
    }
    _pick(place);
  }

  void _pick(Place place) {
    final error = widget.onPick(place);
    if (error != null) return SangaToast.show(error, tone: SangaToastTone.error);
    Navigator.of(context).pop(place);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available = media.size.height - media.viewInsets.bottom - media.padding.top - _topClearance;
    return SizedBox(
      height: math.min(media.size.height * _heightFactor, available),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SangaRouteField.input(
            kind: widget.kind,
            controller: _query,
            hintText: widget.hintText,
            onChanged: _search.search,
            onCleared: _search.clear,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _search,
              builder: (context, _) => ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(vertical: SangaSpacing.md),
                children: [
                  if (_search.isIdle)
                    PlaceSuggestions(
                      onPick: _pick,
                      origin: widget.origin,
                      showsCurrentLocation: widget.kind == SangaStopKind.pickup,
                    )
                  else
                    PlaceSearchResults(search: _search, onPick: _open),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
