enum RatingTag {
  greatDriving('great_driving', 'Great driving', isPositive: true),
  cleanCar('clean_car', 'Clean car', isPositive: true),
  friendly('friendly', 'Friendly', isPositive: true),
  onTime('on_time', 'On time', isPositive: true),
  late('late', 'Late', isPositive: false),
  unsafeDriving('unsafe_driving', 'Unsafe driving', isPositive: false),
  rude('rude', 'Rude', isPositive: false),
  dirtyCar('dirty_car', 'Dirty car', isPositive: false);

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

  Map<String, dynamic> toJson() => {
    'stars': stars,
    'tags': [for (final tag in tags) tag.code],
    'comment': comment.trim(),
  };
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
  static const String message = 'Check your connection and give it another go. Your review is still here.';
}
