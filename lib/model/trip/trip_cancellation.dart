import 'package:sanga_ride/model/trip/trip.dart';
import 'package:sanga_ride/model/trip/wrapup/payment.dart';

enum CancelReason {
  driverLate('driver_late', 'Driver is taking too long', 'Driver taking too long'),
  driverAsked('driver_asked', 'Driver asked me to cancel', 'Driver asked me to cancel'),
  mismatch('vehicle_mismatch', 'Driver or vehicle doesn’t match', 'Driver or vehicle doesn’t match'),
  noLongerNeeded('no_longer_needed', 'I no longer need this ride', 'No longer needed'),
  safety('safety_concern', 'Safety concern', 'Safety concern'),
  other('other', 'Other', 'Other');

  const CancelReason(this.code, this.label, this.summary);

  static const int maxNoteLength = 200;

  final String code;
  final String label;
  final String summary;

  static List<CancelReason> availableFor(TripStatus status) => [
    for (final reason in values)
      if (reason != driverLate || status == TripStatus.driverEnRoute) reason,
  ];

  bool get needsNote => this == other;

  bool get isSafety => this == safety;

  bool isValidWith(String note) => !needsNote || note.trim().isNotEmpty;
}

enum CancelFeeReason {
  freeWindow('free_window'),
  driverFault('driver_fault'),
  driverOnTheWay('driver_on_the_way'),
  driverArrived('driver_arrived'),
  tripStarted('trip_started');

  const CancelFeeReason(this.code);

  final String code;

  String notice(String amount) => switch (this) {
    freeWindow || driverFault || driverOnTheWay =>
      'You’ll pay $amount to cover your driver’s time and distance, as our cancellation policy explains.',
    driverArrived =>
      'Your driver is already at your pickup, so you’ll pay $amount to cover their time, as our cancellation policy explains.',
    tripStarted => 'You’ll pay $amount for the distance you’ve already travelled, as our cancellation policy explains.',
  };

  static CancelFeeReason fromCode(String? code) =>
      values.firstWhere((reason) => reason.code == code, orElse: () => driverOnTheWay);
}

class CancellationRefund {
  const CancellationRefund({required this.amount, required this.method});

  factory CancellationRefund.fromJson(Map<String, dynamic> json) => CancellationRefund(
    amount: (json['amount'] as num).toInt(),
    method: PaymentMethod.fromCode(json['method'] as String),
  );

  final int amount;
  final PaymentMethod method;
}

class CancellationReview {
  const CancellationReview({
    required this.fee,
    required this.feeReason,
    required this.refund,
    required this.paymentMethod,
  });

  factory CancellationReview.fromJson(Map<String, dynamic> json) {
    final refund = json['refund'] as Map?;
    return CancellationReview(
      fee: (json['fee'] as num).toInt(),
      feeReason: CancelFeeReason.fromCode(json['feeReason'] as String?),
      refund: refund == null ? null : CancellationRefund.fromJson(Map<String, dynamic>.from(refund)),
      paymentMethod: PaymentMethod.fromCode(json['paymentMethod'] as String),
    );
  }

  final int fee;
  final CancelFeeReason feeReason;
  final CancellationRefund? refund;
  final PaymentMethod paymentMethod;

  bool get hasFee => fee > 0;
}

class CancelOutcome {
  const CancelOutcome({required this.tripId, required this.feeCharged, required this.message});

  factory CancelOutcome.fromJson(Map<String, dynamic> json) => CancelOutcome(
    tripId: json['tripId'] as String,
    feeCharged: (json['feeCharged'] as num).toInt(),
    message: json['message'] as String,
  );

  final String tripId;
  final int feeCharged;
  final String message;
}

enum CancelFailure {
  reviewUnavailable(
    'review_unavailable',
    'We couldn’t check the fee',
    'Check your connection and give it another go. Your ride is still on.',
    primaryLabel: 'Try again',
    secondaryLabel: 'Not now',
  ),
  connection(
    'connection',
    'We couldn’t cancel your ride',
    'Check your connection and give it another go. Your ride is still on.',
    primaryLabel: 'Try again',
    secondaryLabel: 'Not now',
  ),
  tripNotCancellable(
    'trip_not_cancellable',
    'This ride can’t be cancelled now',
    'Your ride has already moved on, so there’s nothing to cancel.',
    primaryLabel: 'Back to my trip',
  ),
  alreadyCancelled(
    'already_cancelled',
    'This ride is already cancelled',
    'It was cancelled before your request went through.',
    primaryLabel: 'Back to my trip',
  );

  const CancelFailure(this.code, this.title, this.message, {required this.primaryLabel, this.secondaryLabel});

  final String code;
  final String title;
  final String message;
  final String primaryLabel;
  final String? secondaryLabel;

  bool get canRetry => secondaryLabel != null;

  bool get isStale => this == tripNotCancellable || this == alreadyCancelled;

  static CancelFailure fromCode(String? code) =>
      values.firstWhere((failure) => failure.code == code, orElse: () => connection);
}

sealed class CancelState {
  const CancelState();
}

final class CancelChoosing extends CancelState {
  const CancelChoosing({this.reason, this.note = ''});

  final CancelReason? reason;
  final String note;

  bool get canContinue => reason?.isValidWith(note) ?? false;

  CancelChoosing withReason(CancelReason value) => CancelChoosing(reason: value, note: note);

  CancelChoosing withNote(String value) => CancelChoosing(reason: reason, note: value);
}

final class CancelLoadingReview extends CancelState {
  const CancelLoadingReview(this.reason, this.note);

  final CancelReason reason;
  final String note;
}

final class CancelReviewing extends CancelState {
  const CancelReviewing(this.reason, this.note, this.review, {this.isSubmitting = false});

  final CancelReason reason;
  final String note;
  final CancellationReview review;
  final bool isSubmitting;

  CancelReviewing submitting() => CancelReviewing(reason, note, review, isSubmitting: true);
}

final class CancelFailed extends CancelState {
  const CancelFailed(this.failure, this.previous);

  final CancelFailure failure;
  final CancelState previous;
}

final class CancelSettled extends CancelState {
  const CancelSettled(this.failure);

  final CancelFailure failure;
}

final class CancelDone extends CancelState {
  const CancelDone(this.outcome);

  final CancelOutcome outcome;
}
