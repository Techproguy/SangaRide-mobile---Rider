import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/ride/server_deadline.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

export 'package:sanga_ride/model/ride/ride_match_state.dart';

enum RideRequestStatus {
  searching('searching'),
  checking('checking'),
  sending('sending'),
  offers('offers'),
  accepted('accepted'),
  noDriverFound('no_driver_found'),
  cancelled('cancelled'),
  scheduled('scheduled'),
  unknown('unknown');

  const RideRequestStatus(this.code);

  final String code;

  bool get isSearching => this == searching || this == checking || this == sending;

  static RideRequestStatus fromCode(String? code) =>
      enumByCode(values, code == _liveSearching ? searching.code : code, (status) => status.code, unknown);

  static const String _liveSearching = 'requested';
}

enum OfferStatus {
  pending('pending'),
  selected('selected'),
  withdrawn('withdrawn'),
  unknown('unknown');

  const OfferStatus(this.code);

  final String code;

  static OfferStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, unknown);
}

enum OfferUnavailableReason {
  offerUnavailable('offer_unavailable', 'That driver is no longer available.'),
  holdExpired('hold_expired', 'That hold ran out. Pick a driver again.'),
  connection('connection', CommonCopy.offline),
  unknown('unknown', CommonCopy.serverTrouble);

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
  offline(CommonCopy.offlineTitle, CommonCopy.connectionBody),
  serverTrouble('We couldn’t start your search', CommonCopy.serverTrouble),
  couldNotStart('We couldn’t start your search', CommonCopy.serverTrouble),
  connectionLost(
    'We lost the connection',
    'Your request may still be running. Check your connection and we’ll look again.',
  ),
  unconfirmed('We’re not sure it went through', 'We’ll check again. We won’t send your request twice.'),
  quoteExpired('Your price changed', 'We updated it. Have a look, then go again.'),
  tripLost('Let’s plan this one again', 'Your search timed out while the app was closed. Start a new trip from home.');

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
      MatchStep(key: json.str('code'), label: json.str('label'), isDone: json.strOrNull('state') == 'done');

  final String key;
  final String label;
  final bool isDone;
}

class MatchRequest {
  const MatchRequest({
    required this.id,
    required this.status,
    required this.steps,
    required this.searchDeadline,
    this.driver,
  });

  factory MatchRequest.fromJson(Object? body) {
    final json = JsonReader.of(body);
    final matching = json.objectOrNull('matching');
    return MatchRequest(
      id: json.str('id'),
      status: RideRequestStatus.fromCode(json.strOrNull('status')),
      steps: matching?.listOf('steps', MatchStep.fromJson) ?? const [],
      searchDeadline:
          (matching == null ? null : serverInstantOrNull(matching, 'expiresAt')) ?? ServerClock.instance.now(),
      driver: json.raw['driver'] == null ? null : OfferDriver.fromJson(json.raw['driver']),
    );
  }

  MatchRequest withOffers() => MatchRequest(
    id: id,
    status: RideRequestStatus.offers,
    steps: steps,
    searchDeadline: searchDeadline,
    driver: driver,
  );

  final String id;
  final RideRequestStatus status;
  final List<MatchStep> steps;
  final DateTime searchDeadline;
  final OfferDriver? driver;

  ConfirmedTrip get asConfirmedTrip =>
      ConfirmedTrip(tripId: id, etaMinutes: 0, driver: driver ?? OfferDriver.fromJson(const <String, dynamic>{}));

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

  bool get hasName => name != fallbackName;

  factory OfferDriver.fromJson(Object? body) {
    final json = JsonReader.of(body);
    final name = _nameOf(json);
    final firstName = json.strOr('firstName', '').trim();
    return OfferDriver(
      id: json.strOr('id', ''),
      name: name,
      firstName: firstName.isEmpty ? name.split(' ').first : firstName,
      photoUrl: json.strOrNull('photoUrl'),
      isVerified: json.boolOr('verified', false),
      rating: json.doubleOr('rating', 0),
      ridesCompleted: json.intOr('ridesCompleted', 0),
    );
  }

  static String _nameOf(JsonReader json) {
    final full = '${json.strOr('firstName', '')} ${json.strOr('lastName', '')}'.trim();
    for (final candidate in [json.strOr('displayName', ''), json.strOr('name', ''), full]) {
      if (candidate.trim().isNotEmpty) return candidate.trim();
    }
    return fallbackName;
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
    this.fare,
    this.riderFare,
  });

  factory DriverOffer.fromJson(JsonReader json) => DriverOffer(
    id: json.str('id'),
    status: OfferStatus.fromCode(json.strOr('status', OfferStatus.pending.code)),
    counterOffer:
        json.moneyOrNull('counterOfferAmount') ??
        (json.strOrNull('type') == _counter ? json.moneyOrNull('amount') : null),
    etaMinutes: json.intOr('etaMin', 0),
    distanceKm: json.doubleOr('distanceKm', 0),
    driver: OfferDriver.fromJson(json.raw['driver']),
    fare: json.moneyOrNull('fee') ?? json.moneyOrNull('amount'),
    riderFare: json.moneyOrNull('riderFare'),
  );

  static const String _counter = 'counter';

  final String id;
  final OfferStatus status;
  final Money? counterOffer;
  final int etaMinutes;
  final double distanceKm;
  final OfferDriver driver;
  final Money? fare;
  final Money? riderFare;

  bool get isAvailable => status == OfferStatus.pending || status == OfferStatus.selected;

  DriverOffer asWithdrawn() => DriverOffer(
    id: id,
    status: OfferStatus.withdrawn,
    counterOffer: counterOffer,
    etaMinutes: etaMinutes,
    distanceKm: distanceKm,
    driver: driver,
    fare: fare,
    riderFare: riderFare,
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
    this.summary = '',
  });

  factory DriverVehicle.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return DriverVehicle(
      make: json.strOr('make', ''),
      model: json.strOr('model', ''),
      year: json.intOr('year', 0),
      colour: json.strOr('colour', ''),
      plate: json.strOr('plateNumber', ''),
      features: json.strings('featureLabels'),
      summary: json.strOr('display', ''),
    );
  }

  static final RegExp _plateBreaks = RegExp(r'(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])');

  final String make;
  final String model;
  final int year;
  final String colour;
  final String plate;
  final List<String> features;
  final String summary;

  String get title => name.isEmpty ? 'Vehicle' : name;

  String get name {
    final makeModel = [make, model].where((part) => part.isNotEmpty).join(' ');
    if (makeModel.isEmpty) return summary;
    return year == 0 ? makeModel : '$makeModel ($year)';
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
    required this.riderOffer,
    required this.matchLabel,
    required this.distanceAwayKm,
    required this.driver,
    required this.vehicle,
    this.pickup = '',
    this.dropoff = '',
    this.etaMinutes = 0,
  });

  factory DriverHold.fromJson(
    Object? body, {
    required DriverOffer offer,
    required Money fare,
    String pickupTitle = '',
    String dropoffTitle = '',
  }) {
    final json = JsonReader.of(body);
    final card = json.objectOrNull('driver');
    final expiresAt = serverInstantOrNull(json, 'confirmExpiresAt');
    return DriverHold(
      offerId: json.strOr('offerId', offer.id),
      holdExpiresAt: expiresAt == null ? DateTime.now().add(confirmWindow) : deviceDeadlineAt(expiresAt),
      fare: json.moneyOr('fee', offer.counterOffer ?? fare),
      counterOffer: json.moneyOrNull('counterOfferAmount') ?? offer.counterOffer,
      riderOffer: json.moneyOrNull('riderFare') ?? offer.riderFare ?? fare,
      pickup: _placeTitleOf(json.raw['pickup'], pickupTitle),
      dropoff: _placeTitleOf(json.raw['dropoff'], dropoffTitle),
      matchLabel: _matchLabelOf(json.strOrNull('matchLabel')),
      distanceAwayKm: json.doubleOr('distanceKm', offer.distanceKm),
      driver: card == null ? offer.driver : OfferDriver.fromJson(card.raw),
      vehicle: DriverVehicle.fromJson(json.raw['vehicle']),
      etaMinutes: json.intOr('etaMin', offer.etaMinutes),
    );
  }

  static String _placeTitleOf(Object? place, String bookedTitle) {
    if (place is! Map) return bookedTitle;
    final parsed = Place.fromJson(Map<String, dynamic>.from(place));
    return parsed.name.trim().isEmpty && bookedTitle.isNotEmpty ? bookedTitle : parsed.title.trim();
  }

  static String? _matchLabelOf(String? code) {
    if (code == null || code.isEmpty) return null;
    final words = code.replaceAll('_', ' ');
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  static const Duration confirmWindow = Duration(seconds: 120);

  final String offerId;
  final DateTime holdExpiresAt;
  final Money fare;
  final Money riderOffer;
  final Money? counterOffer;
  final String? matchLabel;
  final double distanceAwayKm;
  final OfferDriver driver;
  final DriverVehicle vehicle;
  final String pickup;
  final String dropoff;
  final int etaMinutes;
}

class ConfirmedTrip {
  const ConfirmedTrip({required this.tripId, required this.etaMinutes, required this.driver});

  factory ConfirmedTrip.fromJson(Object? body) {
    final json = JsonReader.of(body);
    return ConfirmedTrip(
      tripId: json.object('ride').str('id'),
      etaMinutes: json.intOr('etaMin', 0),
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
    return ScheduledBooking(id: json.str('id'), scheduledAt: json.time('scheduledFor').toLocal());
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
