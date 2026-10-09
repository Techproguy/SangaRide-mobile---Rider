import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/trip/server_time.dart';
import 'package:sanga_ride/model/trip/trip.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class QuoteLine {
  const QuoteLine({required this.key, required this.label, required this.amount});

  factory QuoteLine.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return QuoteLine(key: reader.str('key'), label: reader.str('label'), amount: reader.integer('amount'));
  }

  final String key;
  final String label;
  final int amount;
}

class StopQuote {
  const StopQuote({
    required this.id,
    required this.expiresAt,
    required this.lines,
    required this.total,
    required this.currentTotal,
  });

  factory StopQuote.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return StopQuote(
      id: reader.str('quoteId'),
      expiresAt: deviceDeadlineOf(reader.str('expiresAt')),
      lines: reader.listOf('lines', (line) => QuoteLine.fromJson(line.raw)),
      total: reader.integer('total'),
      currentTotal: reader.integer('currentTotal'),
    );
  }

  final String id;
  final DateTime expiresAt;
  final List<QuoteLine> lines;
  final int total;
  final int currentTotal;

  int get difference => total - currentTotal;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  Duration get remaining {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}

enum StopResolution { retry, restart, leave }

enum AddStopFailure {
  stopDeclined(
    'stop_declined',
    'Your driver can’t add that stop',
    'It’s a bit too far off your route right now. Your trip stays as it is.',
    StopResolution.restart,
    'Choose another stop',
    'Keep my trip',
  ),
  tooManyStops(
    'too_many_stops',
    'That’s the stop limit',
    'A trip can have up to 3 stops. Your trip stays as it is.',
    StopResolution.leave,
    'Back to my trip',
    null,
  ),
  duplicateStop(
    'duplicate_stop',
    'That place is already on your trip',
    'Pick somewhere different for your stop.',
    StopResolution.restart,
    'Choose another stop',
    'Keep my trip',
  ),
  notChangeable(
    'trip_not_changeable',
    'This trip can’t be changed now',
    'Your ride has moved on, so stops can’t be added any more.',
    StopResolution.leave,
    'Back to my trip',
    null,
  ),
  connection(
    'connection',
    'We couldn’t update your trip',
    'Check your connection and give it another go. Nothing has changed yet.',
    StopResolution.retry,
    'Try again',
    'Not now',
  ),
  unknown(
    'unknown',
    'Something went wrong',
    'Something went wrong on our side. Try again in a moment. Your trip stays as it is.',
    StopResolution.retry,
    'Try again',
    'Not now',
  );

  const AddStopFailure(this.code, this.title, this.message, this.resolution, this.primaryLabel, this.secondaryLabel);

  final String code;
  final String title;
  final String message;
  final StopResolution resolution;
  final String primaryLabel;
  final String? secondaryLabel;

  bool get isRuleBlock => this == tooManyStops || this == duplicateStop;

  static AddStopFailure fromCode(String? code) => enumByCode(values, code, (failure) => failure.code, unknown);

  static AddStopFailure of(Object error) {
    if (error is ApiException && error.kind == ApiFailureKind.rejected) return fromCode(error.code);
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => connection,
      _ => unknown,
    };
  }
}

sealed class AddStopState {
  const AddStopState();
}

final class AddStopDrafting extends AddStopState {
  const AddStopDrafting(this.added);

  final List<Place> added;
}

final class AddStopPlacing extends AddStopState {
  const AddStopPlacing(this.added, this.place);

  final List<Place> added;
  final Place place;
}

final class AddStopQuoting extends AddStopState {
  const AddStopQuoting(this.added);

  final List<Place> added;
}

final class AddStopReviewing extends AddStopState {
  const AddStopReviewing(this.added, this.quote, {this.isRefreshed = false, this.isApplying = false});

  final List<Place> added;
  final StopQuote quote;
  final bool isRefreshed;
  final bool isApplying;

  AddStopReviewing applying() => AddStopReviewing(added, quote, isRefreshed: isRefreshed, isApplying: true);
}

final class AddStopFailed extends AddStopState {
  const AddStopFailed(this.reason, this.added, {this.quote, this.serverMessage});

  final AddStopFailure reason;
  final List<Place> added;
  final StopQuote? quote;
  final String? serverMessage;

  String get message => serverMessage ?? reason.message;
}

final class AddStopApplied extends AddStopState {
  const AddStopApplied(this.trip);

  final Trip trip;
}

enum TripNotice {
  fareUpdated('Your fare has been updated'),
  packagePickedUp('Package picked up. You can make your payment now');

  const TripNotice(this.message);

  final String message;
}
