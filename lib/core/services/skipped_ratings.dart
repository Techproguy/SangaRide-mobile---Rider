import 'package:sanga_ride/core/services/session_storage.dart';
import 'package:sanga_ride/core/storage/draft_keys.dart';

abstract final class SkippedRatings {
  static const int _kept = 20;
  static const String _idsKey = 'ids';

  static bool contains(String tripId) => _ids.contains(tripId);

  static Future<void> add(String tripId) => SessionStorage.drafts.write(DraftKeys.skippedRatings, {
    _idsKey: [tripId, ..._ids.where((id) => id != tripId)].take(_kept).toList(),
  });

  static List<String> get _ids {
    final stored = SessionStorage.drafts.read(DraftKeys.skippedRatings)?[_idsKey];
    return [
      if (stored is List)
        for (final id in stored) '$id',
    ];
  }
}
