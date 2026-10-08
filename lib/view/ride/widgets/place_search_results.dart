import 'package:flutter/material.dart';
import 'package:sanga_ride/controller/rider/place_search.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class PlaceSearchResults extends StatelessWidget {
  const PlaceSearchResults({super.key, required this.search, required this.onPick});

  final PlaceSearch search;
  final ValueChanged<PlaceAutocomplete> onPick;

  static String subtitleOf(PlaceAutocomplete prediction) {
    final distance = prediction.distanceMeters;
    return [if (distance != null) SangaDistance.format(distance), ?prediction.secondaryText].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return switch (search.status) {
      PlaceSearchStatus.idle => const SizedBox.shrink(),
      PlaceSearchStatus.searching => const Padding(
        padding: EdgeInsets.all(SangaSpacing.xl),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: SangaColors.primary),
          ),
        ),
      ),
      PlaceSearchStatus.failed => SangaInlineMessage(
        title: 'Search hit a bump',
        message: 'Check your connection and give it another go.',
        actionLabel: 'Try again',
        onAction: search.retry,
      ),
      PlaceSearchStatus.empty => SangaInlineMessage(
        title: 'No matches for “${search.query}”',
        message: 'Try a street, area or landmark nearby.',
      ),
      PlaceSearchStatus.results => SangaListGroup(
        children: [
          for (final prediction in search.results)
            SangaListRow.place(
              title: prediction.title,
              subtitle: subtitleOf(prediction),
              trailing: search.isOpening(prediction) ? SangaListRow.spinner : SangaListRow.chevron,
              onTap: () => onPick(prediction),
            ),
        ],
      ),
    };
  }
}
