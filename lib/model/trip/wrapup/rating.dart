import 'package:sanga_ride/core/copy/common_copy.dart';

enum RatingTag {
  fastAndPolite('FAST_AND_POLITE', 'Fast and polite', isPositive: true),
  cleanCar('CLEAN_CAR', 'Clean car', isPositive: true),
  greatConversation('GREAT_CONVERSATION', 'Great conversation', isPositive: true),
  safeDriving('SAFE_DRIVING', 'Safe driving', isPositive: true),
  onTime('ON_TIME', 'On time', isPositive: true),
  expertNavigation('EXPERT_NAVIGATION', 'Expert navigation', isPositive: true),
  lateArrival('LATE_ARRIVAL', 'Late arrival', isPositive: false),
  unsafeDriving('UNSAFE_DRIVING', 'Unsafe driving', isPositive: false),
  rude('RUDE', 'Rude', isPositive: false),
  dirtyCar('DIRTY_CAR', 'Dirty car', isPositive: false),
  wrongRoute('WRONG_ROUTE', 'Wrong route', isPositive: false);

  const RatingTag(this.code, this.label, {required this.isPositive});

  final String code;
  final String label;
  final bool isPositive;

  static List<RatingTag> forStars(int stars) {
    if (stars <= 0) return const [];
    return [
      for (final tag in values)
        if (tag.isPositive == stars >= 4) tag,
    ];
  }
}

class DriverRating {
  const DriverRating({this.stars = 0, this.tags = const {}, this.comment = ''});

  static const int maxCommentLength = 200;

  final int stars;
  final Set<RatingTag> tags;
  final String comment;

  bool get hasStars => stars > 0;

  List<RatingTag> get availableTags => RatingTag.forStars(stars);

  DriverRating withStars(int value) {
    final available = RatingTag.forStars(value);
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

  DriverRating withComment(String value) => DriverRating(stars: stars, tags: tags, comment: value);

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
  static const String message = '${CommonCopy.connectionBody} Your review is still here.';
}
