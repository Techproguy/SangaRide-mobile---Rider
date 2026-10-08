enum RideRequestStatus {
  searching('searching'),
  checking('checking'),
  sending('sending'),
  offers('offers'),
  noDriverFound('no_driver_found'),
  cancelled('cancelled');

  const RideRequestStatus(this.code);

  final String code;

  bool get isSearching => this == searching || this == checking || this == sending;

  static RideRequestStatus fromCode(String code) => values.firstWhere(
    (status) => status.code == code,
    orElse: () => throw FormatException('Unknown ride request status: $code'),
  );
}

enum OfferStatus {
  pending('pending'),
  withdrawn('withdrawn');

  const OfferStatus(this.code);

  final String code;

  static OfferStatus fromCode(String code) => values.firstWhere(
    (status) => status.code == code,
    orElse: () => throw FormatException('Unknown offer status: $code'),
  );
}

enum OfferUnavailableReason {
  offerUnavailable('offer_unavailable', 'That driver is no longer available.'),
  holdExpired('hold_expired', 'That hold ran out. Pick a driver again.'),
  unknown('unknown', 'Something went wrong with that driver. Give it another go.');

  const OfferUnavailableReason(this.code, this.message);

  final String code;
  final String message;

  bool get removesOffer => this == offerUnavailable;

  static OfferUnavailableReason fromCode(String? code) =>
      values.firstWhere((reason) => reason.code == code, orElse: () => unknown);
}

enum MatchFailure {
  noDriverFound('No driver found', 'Drivers are busy right now. Give it another go in a moment.'),
  couldNotStart('We couldn’t start your search', 'Check your connection and give it another go.'),
  connectionLost('We lost the connection', 'We stopped your request. Check your connection and give it another go.');

  const MatchFailure(this.title, this.message);

  final String title;
  final String message;
}

DateTime _localDeadline(Map<String, dynamic> json, String key) {
  final deadline = DateTime.parse(json[key] as String);
  final serverTime = DateTime.parse(json['serverTime'] as String);
  return DateTime.now().add(deadline.difference(serverTime));
}

class MatchStep {
  const MatchStep({required this.key, required this.label, required this.isDone});

  factory MatchStep.fromJson(Map<String, dynamic> json) =>
      MatchStep(key: json['key'] as String, label: json['label'] as String, isDone: json['done'] as bool);

  final String key;
  final String label;
  final bool isDone;
}

class MatchRequest {
  const MatchRequest({required this.id, required this.status, required this.steps, required this.searchExpiresAt});

  factory MatchRequest.fromJson(Map<String, dynamic> json) => MatchRequest(
    id: json['id'] as String,
    status: RideRequestStatus.fromCode(json['status'] as String),
    steps: [for (final step in json['steps'] as List) MatchStep.fromJson(Map<String, dynamic>.from(step as Map))],
    searchExpiresAt: _localDeadline(json, 'searchExpiresAt'),
  );

  final String id;
  final RideRequestStatus status;
  final List<MatchStep> steps;
  final DateTime searchExpiresAt;

  int get stepsDone => steps.where((step) => step.isDone).length;

  List<String> get stepLabels => [for (final step in steps) step.label];

  bool get hasSearchExpired => status.isSearching && DateTime.now().isAfter(searchExpiresAt);
}

class OfferDriver {
  const OfferDriver({
    required this.id,
    required this.name,
    required this.firstName,
    required this.photoUrl,
    required this.isVerified,
    required this.rating,
    required this.ridesCompleted,
  });

  factory OfferDriver.fromJson(Map<String, dynamic> json) => OfferDriver(
    id: json['id'] as String,
    name: json['name'] as String,
    firstName: json['firstName'] as String,
    photoUrl: json['photoUrl'] as String?,
    isVerified: json['verified'] as bool,
    rating: (json['rating'] as num).toDouble(),
    ridesCompleted: (json['ridesCompleted'] as num).toInt(),
  );

  final String id;
  final String name;
  final String firstName;
  final String? photoUrl;
  final bool isVerified;
  final double rating;
  final int ridesCompleted;

  String get ridesLabel => switch (ridesCompleted) {
    0 => 'New driver',
    1 => '1 ride completed',
    _ => '$ridesCompleted rides completed',
  };
}

class DriverOffer {
  const DriverOffer({
    required this.id,
    required this.status,
    required this.counterOffer,
    required this.etaMinutes,
    required this.distanceKm,
    required this.driver,
  });

  factory DriverOffer.fromJson(Map<String, dynamic> json) => DriverOffer(
    id: json['id'] as String,
    status: OfferStatus.fromCode(json['status'] as String),
    counterOffer: (json['counterOffer'] as num?)?.toInt(),
    etaMinutes: (json['etaMinutes'] as num).toInt(),
    distanceKm: (json['distanceKm'] as num).toDouble(),
    driver: OfferDriver.fromJson(Map<String, dynamic>.from(json['driver'] as Map)),
  );

  final String id;
  final OfferStatus status;
  final int? counterOffer;
  final int etaMinutes;
  final double distanceKm;
  final OfferDriver driver;

  bool get isAvailable => status == OfferStatus.pending;

  DriverOffer asWithdrawn() => DriverOffer(
    id: id,
    status: OfferStatus.withdrawn,
    counterOffer: counterOffer,
    etaMinutes: etaMinutes,
    distanceKm: distanceKm,
    driver: driver,
  );
}

class OfferRow {
  const OfferRow(this.offer, {this.isLeaving = false});

  final DriverOffer offer;
  final bool isLeaving;

  OfferRow asLeaving() => OfferRow(offer, isLeaving: true);

  OfferRow asWithdrawn() => OfferRow(offer.asWithdrawn(), isLeaving: isLeaving);
}

class DriverVehicle {
  const DriverVehicle({
    required this.make,
    required this.model,
    required this.year,
    required this.colour,
    required this.plate,
    required this.features,
  });

  factory DriverVehicle.fromJson(Map<String, dynamic> json) => DriverVehicle(
    make: json['make'] as String,
    model: json['model'] as String,
    year: (json['year'] as num).toInt(),
    colour: json['colour'] as String,
    plate: json['plate'] as String,
    features: [for (final feature in json['features'] as List) feature as String],
  );

  static final RegExp _plateBreaks = RegExp(r'(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])');

  final String make;
  final String model;
  final int year;
  final String colour;
  final String plate;
  final List<String> features;

  String get title => '$make $model ($year)';

  String get colourLabel => colour.isEmpty ? colour : '${colour[0].toUpperCase()}${colour.substring(1)}';

  String get plateLabel => plate.replaceAll(_plateBreaks, ' ');
}

class DriverHold {
  const DriverHold({
    required this.offerId,
    required this.holdExpiresAt,
    required this.fare,
    required this.counterOffer,
    required this.matchLabel,
    required this.distanceAwayKm,
    required this.driver,
    required this.vehicle,
  });

  factory DriverHold.fromJson(Map<String, dynamic> json) {
    final hold = Map<String, dynamic>.from(json['hold'] as Map);
    final card = Map<String, dynamic>.from(json['driver'] as Map);
    return DriverHold(
      offerId: hold['offerId'] as String,
      holdExpiresAt: _localDeadline(hold, 'holdExpiresAt'),
      fare: (hold['fare'] as num).toInt(),
      counterOffer: (hold['counterOffer'] as num?)?.toInt(),
      matchLabel: hold['matchLabel'] as String?,
      distanceAwayKm: (card['distanceAwayKm'] as num).toDouble(),
      driver: OfferDriver.fromJson(card),
      vehicle: DriverVehicle.fromJson(Map<String, dynamic>.from(card['vehicle'] as Map)),
    );
  }

  final String offerId;
  final DateTime holdExpiresAt;
  final int fare;
  final int? counterOffer;
  final String? matchLabel;
  final double distanceAwayKm;
  final OfferDriver driver;
  final DriverVehicle vehicle;
}

class ConfirmedTrip {
  const ConfirmedTrip({required this.tripId, required this.etaMinutes, required this.driver});

  factory ConfirmedTrip.fromJson(Map<String, dynamic> json) => ConfirmedTrip(
    tripId: json['tripId'] as String,
    etaMinutes: (json['etaMinutes'] as num).toInt(),
    driver: OfferDriver.fromJson(Map<String, dynamic>.from(json['driver'] as Map)),
  );

  final String tripId;
  final int etaMinutes;
  final OfferDriver driver;
}

class ScheduledBooking {
  const ScheduledBooking({required this.id, required this.scheduledAt});

  factory ScheduledBooking.fromJson(Map<String, dynamic> json) =>
      ScheduledBooking(id: json['id'] as String, scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal());

  final String id;
  final DateTime scheduledAt;
}

sealed class RideMatchState {
  const RideMatchState();
}

final class MatchIdle extends RideMatchState {
  const MatchIdle();
}

final class MatchStarting extends RideMatchState {
  const MatchStarting();
}

final class MatchSearching extends RideMatchState {
  const MatchSearching(this.request);

  final MatchRequest request;
}

final class MatchOffersReady extends RideMatchState {
  const MatchOffersReady({required this.request, required this.continueAt});

  final MatchRequest request;
  final DateTime continueAt;
}

final class MatchScheduled extends RideMatchState {
  const MatchScheduled(this.booking);

  final ScheduledBooking booking;
}

final class MatchNoDriver extends RideMatchState {
  const MatchNoDriver();
}

final class MatchCancelled extends RideMatchState {
  const MatchCancelled();
}

final class MatchFailed extends RideMatchState {
  const MatchFailed(this.reason);

  final MatchFailure reason;
}

final class MatchOffersLoading extends RideMatchState {
  const MatchOffersLoading();
}

final class MatchOffersFailed extends RideMatchState {
  const MatchOffersFailed();
}

sealed class MatchBrowsing extends RideMatchState {
  const MatchBrowsing(this.rows);

  final List<OfferRow> rows;

  MatchBrowsing withRows(List<OfferRow> rows);
}

final class MatchOffersListed extends MatchBrowsing {
  const MatchOffersListed(super.rows, {this.acceptingOfferId});

  final String? acceptingOfferId;

  @override
  MatchOffersListed withRows(List<OfferRow> rows) => MatchOffersListed(rows, acceptingOfferId: acceptingOfferId);
}

final class MatchHolding extends MatchBrowsing {
  const MatchHolding(super.rows, {required this.hold, this.isConfirming = false});

  final DriverHold hold;
  final bool isConfirming;

  @override
  MatchHolding withRows(List<OfferRow> rows) => MatchHolding(rows, hold: hold, isConfirming: isConfirming);
}

final class MatchConfirmed extends RideMatchState {
  const MatchConfirmed(this.trip);

  final ConfirmedTrip trip;
}
