enum RatingAudience { ride, delivery, both }

enum RatingTag {
  greatDriving('great_driving', 'Great driving', isPositive: true, audience: RatingAudience.ride),
  cleanCar('clean_car', 'Clean car', isPositive: true, audience: RatingAudience.ride),
  carefulHandling('careful_handling', 'Careful handling', isPositive: true, audience: RatingAudience.delivery),
  goodUpdates('good_updates', 'Kept me updated', isPositive: true, audience: RatingAudience.delivery),
  friendly('friendly', 'Friendly', isPositive: true),
  onTime('on_time', 'On time', isPositive: true),
  late('late', 'Late', isPositive: false),
  unsafeDriving('unsafe_driving', 'Unsafe driving', isPositive: false, audience: RatingAudience.ride),
  roughHandling('rough_handling', 'Rough handling', isPositive: false, audience: RatingAudience.delivery),
  hardToReach('hard_to_reach', 'Hard to reach', isPositive: false, audience: RatingAudience.delivery),
  rude('rude', 'Rude', isPositive: false),
  dirtyCar('dirty_car', 'Dirty car', isPositive: false, audience: RatingAudience.ride);

  const RatingTag(this.code, this.label, {required this.isPositive, this.audience = RatingAudience.both});

  final String code;
  final String label;
  final bool isPositive;
  final RatingAudience audience;

  bool isFor({required bool isDelivery}) =>
      audience == RatingAudience.both || (audience == RatingAudience.delivery) == isDelivery;

  static List<RatingTag> forStars(int stars, {bool isDelivery = false}) {
    if (stars <= 0) return const [];
    return [
      for (final tag in values)
        if (tag.isPositive == stars >= 4 && tag.isFor(isDelivery: isDelivery)) tag,
    ];
  }
}

class DriverRating {
  const DriverRating({this.stars = 0, this.tags = const {}, this.comment = '', this.isDelivery = false});

  static const int maxCommentLength = 200;

  final int stars;
  final Set<RatingTag> tags;
  final String comment;
  final bool isDelivery;

  bool get hasStars => stars > 0;

  List<RatingTag> get availableTags => RatingTag.forStars(stars, isDelivery: isDelivery);

  DriverRating withStars(int value) {
    final available = RatingTag.forStars(value, isDelivery: isDelivery);
    return DriverRating(
      stars: value,
      tags: {
        for (final tag in tags)
          if (available.contains(tag)) tag,
      },
      comment: comment,
      isDelivery: isDelivery,
    );
  }

  DriverRating toggled(RatingTag tag) {
    final next = {...tags};
    if (!next.remove(tag)) next.add(tag);
    return DriverRating(stars: stars, tags: next, comment: comment, isDelivery: isDelivery);
  }

  DriverRating withComment(String value) =>
      DriverRating(stars: stars, tags: tags, comment: value, isDelivery: isDelivery);

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
