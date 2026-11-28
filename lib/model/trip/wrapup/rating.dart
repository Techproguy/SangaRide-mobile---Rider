import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class RatingTag {
  const RatingTag({required this.code, required this.label});

  factory RatingTag.fromReader(JsonReader reader) =>
      RatingTag(code: reader.str('code'), label: reader.str('label'));

  // TODO(#270): drop these code lists when GET /ratings/tags returns isPositive, appliesTo and minStars
  static const Set<String> _negativeCodes = {
    'LATE_ARRIVAL',
    'UNSAFE_DRIVING',
    'RUDE',
    'DIRTY_CAR',
    'WRONG_ROUTE',
  };
  static const Set<String> _positiveCodes = {
    'FAST_AND_POLITE',
    'CLEAN_CAR',
    'GREAT_CONVERSATION',
    'SAFE_DRIVING',
    'ON_TIME',
    'EXPERT_NAVIGATION',
  };
  static const Set<String> _ridesOnlyCodes = {
    'CLEAN_CAR',
    'GREAT_CONVERSATION',
    'EXPERT_NAVIGATION',
    'DIRTY_CAR',
    'WRONG_ROUTE',
  };

  final String code;
  final String label;

  bool get suitsDelivery => !_ridesOnlyCodes.contains(code);

  bool isOfferedFor(int stars) {
    if (stars <= 0) return false;
    return stars >= 4
        ? !_negativeCodes.contains(code)
        : !_positiveCodes.contains(code);
  }

  @override
  bool operator ==(Object other) => other is RatingTag && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

class DriverRating {
  const DriverRating({this.stars = 0, this.tags = const {}, this.comment = ''});

  static const int maxCommentLength = 200;

  final int stars;
  final Set<RatingTag> tags;
  final String comment;

  bool get hasStars => stars > 0;

  DriverRating withStars(int value, {required List<RatingTag> available}) {
    return DriverRating(
      stars: value,
      tags: {
        for (final tag in tags)
          if (available.contains(tag)) tag,
      },
      comment: comment,
    );
  }

  DriverRating toggled(RatingTag tag) {
    final next = {...tags};
    if (!next.remove(tag)) next.add(tag);
    return DriverRating(stars: stars, tags: next, comment: comment);
  }

  DriverRating withComment(String value) =>
      DriverRating(stars: stars, tags: tags, comment: value);

  Map<String, dynamic> toJson() {
    final review = comment.trim();
    return {
      'stars': stars,
      if (review.isNotEmpty) 'review': review,
      if (tags.isNotEmpty) 'tags': [for (final tag in tags) tag.code],
    };
  }
}

sealed class RatingState {
  const RatingState(this.rating);

  final DriverRating rating;
}

final class RatingEditing extends RatingState {
  const RatingEditing(super.rating);
}

final class RatingSubmitting extends RatingState {
  const RatingSubmitting(super.rating);
}

final class RatingSubmitted extends RatingState {
  const RatingSubmitted(super.rating);
}

final class RatingFailed extends RatingState {
  const RatingFailed(super.rating);

  static const String title = 'We couldn’t send your rating';
  static const String message =
      '${SangaCommonCopy.connectionAnotherGo} Your review is still here.';
}
