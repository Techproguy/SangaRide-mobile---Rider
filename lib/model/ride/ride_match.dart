import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride/model/ride/server_deadline.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum RideRequestStatus {
  searching('searching'),
  checking('checking'),
  sending('sending'),
  offers('offers'),
  noDriverFound('no_driver_found'),
  cancelled('cancelled'),
  scheduled('scheduled'),
  unknown('unknown');

  const RideRequestStatus(this.code);

  final String code;

  bool get isSearching => this == searching || this == checking || this == sending;

  static RideRequestStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, unknown);
}

enum OfferStatus {
  pending('pending'),
  withdrawn('withdrawn'),
  unknown('unknown');

  const OfferStatus(this.code);

  final String code;

  static OfferStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, unknown);
}

enum OfferUnavailableReason {
  offerUnavailable('offer_unavailable', 'That driver is no longer available.'),
  holdExpired('hold_expired', 'That hold ran out. Pick a driver again.'),
  connection('connection', 'You’re offline. Check your connection and give it another go.'),
  unknown('unknown', 'Something went wrong on our side. Try again in a moment.');

  const OfferUnavailableReason(this.code, this.message);

  final String code;
  final String message;

  bool get removesOffer => this == offerUnavailable;

  static OfferUnavailableReason fromCode(String? code) => enumByCode(values, code, (reason) => reason.code, unknown);

  static OfferUnavailableReason of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => connection,
    ProblemRejected(:final code) => fromCode(code),
    _ => unknown,
  };
}

enum MatchFailure {
  noDriverFound('No driver found', 'Drivers are busy right now. Give it another go in a moment.'),
  offline('You’re offline', 'Check your connection and give it another go.'),
  serverTrouble('We couldn’t start your search', 'Something went wrong on our side. Try again in a moment.'),
  couldNotStart('We couldn’t start your search', 'Something went wrong on our side. Try again in a moment.'),
  connectionLost(
    'We lost the connection',
    'Your request may still be running. Check your connection and we’ll look again.',
  ),
  unconfirmed('We’re not sure it went through', 'We’ll check again. We won’t send your request twice.'),
  quoteExpired('Your price changed', 'We updated it. Have a look, then go again.');

  const MatchFailure(this.title, this.message);

  final String title;
  final String message;

  static MatchFailure of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => offline,
    ProblemServer() => serverTrouble,
    _ => couldNotStart,
  };
}

class MatchStep {
  const MatchStep({required this.key, required this.label, required this.isDone});

  factory MatchStep.fromJson(JsonReader json) =>
      MatchStep(key: json.str('key'), label: json.str('label'), isDone: json.boolOr('done', false));

  final String key;
  final String label;
  final bool isDone;
}

class MatchRequest {
  const MatchRequest({required this.id, required this.status, required this.steps, required this.searchDeadline});

  factory MatchRequest.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return MatchRequest(
      id: json.str('id'),
      status: RideRequestStatus.fromCode(json.strOrNull('status')),
      steps: json.listOf('steps', MatchStep.fromJson),
      searchDeadline: serverInstantOrNull(json, 'searchExpiresAt') ?? ServerClock.instance.now(),
    );
  }

  final String id;
  final RideRequestStatus status;
  final List<MatchStep> steps;
  final DateTime searchDeadline;

  int get stepsDone => steps.where((step) => step.isDone).length;

  List<String> get stepLabels => [for (final step in steps) step.label];

  bool get hasSearchExpired => status.isSearching && hasServerPassed(searchDeadline);
}

class OfferDriver {
  static const String fallbackName = 'Driver';

  const OfferDriver({
    required this.id,
    required this.name,
    required this.firstName,
    required this.photoUrl,
    required this.isVerified,
    required this.rating,
    required this.ridesCompleted,
  });

  factory OfferDriver.fromJson(Object? body) {
    final json = JsonReader.of(body);
    final name = json.strOr('name', fallbackName);
    return OfferDriver(
      id: json.strOr('id', ''),
      name: name,
      firstName: json.strOr('firstName', name.split(' ').first),
      photoUrl: json.strOrNull('photoUrl'),
      isVerified: json.boolOr('verified', false),
      rating: json.doubleOr('rating', 0),
      ridesCompleted: json.intOr('ridesCompleted', 0),
    );
  }

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

  factory DriverOffer.fromJson(JsonReader json) => DriverOffer(
    id: json.str('id'),
    status: OfferStatus.fromCode(json.strOrNull('status')),
    counterOffer: json.intOrNull('counterOffer'),
    etaMinutes: json.intOr('etaMinutes', 0),
    distanceKm: json.doubleOr('distanceKm', 0),
    driver: OfferDriver.fromJson(json.raw['driver']),
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

  factory DriverVehicle.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return DriverVehicle(
      make: json.strOr('make', ''),
      model: json.strOr('model', ''),
      year: json.intOr('year', 0),
      colour: json.strOr('colour', ''),
      plate: json.strOr('plate', ''),
      features: json.strings('features'),
    );
  }

  static final RegExp _plateBreaks = RegExp(r'(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])');

  final String make;
  final String model;
  final int year;
  final String colour;
  final String plate;
  final List<String> features;

  String get title {
    final name = [make, model].where((part) => part.isNotEmpty).join(' ');
    if (name.isEmpty) return 'Vehicle';
    return year == 0 ? name : '$name ($year)';
  }

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
    this.etaMinutes = 0,
  });

  factory DriverHold.fromJson(Object? body, {int etaMinutes = 0}) {
    final json = JsonReader.of(body);
    final hold = json.object('hold');
    final card = json.object('driver');
    return DriverHold(
      offerId: hold.str('offerId'),
      holdExpiresAt: deviceDeadlineAt(serverInstantOf(hold, 'holdExpiresAt')),
      fare: hold.integer('fare'),
      counterOffer: hold.intOrNull('counterOffer'),
      matchLabel: hold.strOrNull('matchLabel'),
      distanceAwayKm: card.doubleOr('distanceAwayKm', 0),
      driver: OfferDriver.fromJson(card),
      vehicle: DriverVehicle.fromJson(card.raw['vehicle']),
      etaMinutes: etaMinutes,
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
  final int etaMinutes;

  DriverHold withEta(int minutes) => DriverHold(
    offerId: offerId,
    holdExpiresAt: holdExpiresAt,
    fare: fare,
    counterOffer: counterOffer,
    matchLabel: matchLabel,
    distanceAwayKm: distanceAwayKm,
    driver: driver,
    vehicle: vehicle,
    etaMinutes: minutes,
  );
}

class ConfirmedTrip {
  const ConfirmedTrip({required this.tripId, required this.etaMinutes, required this.driver});

  factory ConfirmedTrip.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return ConfirmedTrip(
      tripId: json.str('tripId'),
      etaMinutes: json.intOr('etaMinutes', 0),
      driver: OfferDriver.fromJson(json.raw['driver']),
    );
  }

  final String tripId;
  final int etaMinutes;
  final OfferDriver driver;
}

class ScheduledBooking {
  const ScheduledBooking({required this.id, required this.scheduledAt});

  factory ScheduledBooking.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return ScheduledBooking(id: json.str('id'), scheduledAt: json.time('scheduledAt').toLocal());
  }

  final String id;
  final DateTime scheduledAt;
}

sealed class CreateOutcome {
  const CreateOutcome();
}

final class RequestCreated extends CreateOutcome {
  const RequestCreated(this.request);

  final MatchRequest request;
}

final class RequestScheduled extends CreateOutcome {
  const RequestScheduled(this.booking);

  final ScheduledBooking booking;
}

sealed class RideMatchState {
  const RideMatchState();
}

final class MatchIdle extends RideMatchState {
  const MatchIdle();
}

final class MatchStarting extends RideMatchState {
  const MatchStarting({this.isChecking = false});

  final bool isChecking;
}

final class MatchResuming extends RideMatchState {
  const MatchResuming();
}

final class MatchSearching extends RideMatchState {
  const MatchSearching(this.request, {this.link = LinkState.live});

  final MatchRequest request;
  final LinkState link;

  bool get isReconnecting => link != LinkState.live;
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
  const MatchCancelled({this.isConfirmed = true});

  final bool isConfirmed;
}

final class MatchAwaitingApproval extends RideMatchState {
  const MatchAwaitingApproval(this.approval);

  final PendingApproval approval;
}

final class MatchBlocked extends RideMatchState {
  const MatchBlocked(this.block);

  final GroupRideBlock block;
}

final class MatchFailed extends RideMatchState {
  const MatchFailed(this.reason, {this.code, this.data = const {}});

  final MatchFailure reason;
  final String? code;
  final Map<String, dynamic> data;
}

final class MatchOffersLoading extends RideMatchState {
  const MatchOffersLoading();
}

final class MatchOffersFailed extends RideMatchState {
  const MatchOffersFailed({this.problem = RideLoadProblem.connection});

  final RideLoadProblem problem;
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
