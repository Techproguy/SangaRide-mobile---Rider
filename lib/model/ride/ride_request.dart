import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum TripType {
  oneWay('one_way', 'One way', 'Go to a destination'),
  roundTrip('round_trip', 'Round trip', 'Go there and come back'),
  hourly('hourly', 'Hourly', 'Keep a driver for a set time'),
  intercity('intercity', 'Intercity', 'Travel between cities'),
  airport('airport', 'Airport', 'Get picked up from the airport'),
  delivery('delivery', 'Delivery', 'Send a package across town');

  const TripType(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  static TripType fromCode(String? code) => enumByCode(values, code, (type) => type.code, oneWay);

  static List<TripType> get selectable => [
    for (final type in values)
      if (type != airport && type != delivery) type,
  ];

  bool get isAlwaysScheduled => this == intercity;

  bool get allowsRepeat => this == oneWay;

  bool get needsReturn => this == roundTrip;

  bool get handlesOwnRejections => this == delivery;
}

enum RideCategory { go, plus, xl, lux, moto, assist }

class RideOption {
  const RideOption({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.seats,
    required this.pricePerKm,
  });

  factory RideOption.fromJson(JsonReader json) {
    final category = RideCategory.values.asNameMap()[json.strOrNull('code')];
    if (category == null) throw JsonFormatError('Unknown ride class', json.raw['code']);
    final seatsMin = json.intOr('seatsMin', 1);
    final seatsMax = json.intOr('seatsMax', seatsMin);
    return RideOption(
      id: json.str('id'),
      category: category,
      name: json.str('name'),
      description: json.strOr('tagline', ''),
      seats: seatsMin == seatsMax ? '$seatsMax' : '$seatsMin-$seatsMax',
      pricePerKm: json.money('perKmRate'),
    );
  }

  final String id;
  final RideCategory category;
  final String name;
  final String description;
  final String seats;
  final Money pricePerKm;

  int get maxSeats => int.tryParse(seats.split('-').last.trim()) ?? 1;
}

enum PricingOption {
  standard('Standard', 'Best balance of price and speed', null),
  fairFare('Fair Fare', 'You set the price', null),
  saver('Saver', 'Lowest price, longest wait', 'Saver discount'),
  priority('Priority', 'Faster matching', 'Priority extra');

  bool get isNegotiated => this == fairFare;

  const PricingOption(this.label, this.description, this.adjustmentLabel);

  String get code => switch (this) {
    fairFare => 'fair',
    _ => name,
  };

  static PricingOption? fromCode(String? code) => values.where((option) => option.code == code).firstOrNull;

  final String label;
  final String description;
  final String? adjustmentLabel;
}

enum RideTiming {
  now('Now', 'Find a driver immediately'),
  later('Later', 'Schedule a ride'),
  repeat('Repeat', 'Set up a recurring ride');

  const RideTiming(this.label, this.description);

  final String label;
  final String description;

  bool get isScheduled => this != now;
}

class RidePreferences {
  const RidePreferences({
    this.petFriendly = false,
    this.quietRide = false,
    this.femaleDriver = false,
    this.childSeat = false,
    this.extraLuggage = false,
    this.driverLanguage = 'English',
  });

  final bool petFriendly;
  final bool quietRide;
  final bool femaleDriver;
  final bool childSeat;
  final bool extraLuggage;
  final String driverLanguage;

  List<String> get activeLabels => [
    if (petFriendly) 'Pet friendly',
    if (quietRide) 'Quiet ride',
    if (femaleDriver) 'Female driver',
    if (childSeat) 'Child seat',
    if (extraLuggage) 'Extra luggage',
  ];

  RidePreferences copyWith({
    bool? petFriendly,
    bool? quietRide,
    bool? femaleDriver,
    bool? childSeat,
    bool? extraLuggage,
    String? driverLanguage,
  }) => RidePreferences(
    petFriendly: petFriendly ?? this.petFriendly,
    quietRide: quietRide ?? this.quietRide,
    femaleDriver: femaleDriver ?? this.femaleDriver,
    childSeat: childSeat ?? this.childSeat,
    extraLuggage: extraLuggage ?? this.extraLuggage,
    driverLanguage: driverLanguage ?? this.driverLanguage,
  );

  @override
  bool operator ==(Object other) =>
      other is RidePreferences &&
      other.petFriendly == petFriendly &&
      other.quietRide == quietRide &&
      other.femaleDriver == femaleDriver &&
      other.childSeat == childSeat &&
      other.extraLuggage == extraLuggage &&
      other.driverLanguage == driverLanguage;

  @override
  int get hashCode => Object.hash(petFriendly, quietRide, femaleDriver, childSeat, extraLuggage, driverLanguage);

  Map<String, dynamic> toJson() => {
    'petFriendly': petFriendly,
    'quietRide': quietRide,
    'femaleDriver': femaleDriver,
    'childSeat': childSeat,
    'extraLuggage': extraLuggage,
    'driverLanguage': driverLanguage,
  };
}

class FareEstimate {
  const FareEstimate({
    required this.baseFare,
    required this.distanceKm,
    required this.distanceFare,
    required this.discount,
    required this.boost,
    required this.total,
    required this.pricing,
    this.ratePerKm,
    this.hours,
    this.hourlyRate,
    this.meetGreetFee,
    this.quoteId,
    this.fairFare,
  });

  factory FareEstimate.fromJson(Object? body) {
    final json = JsonReader.of(body);
    final pricing = <PricingOption, Money>{
      for (final card in json.listOf('pricingOptions', (item) => item))
        if ((PricingOption.fromCode(card.strOrNull('code')), card.moneyOrNull('price')) case (final option?, final price?))
          option: price,
    };
    final lines = {for (final line in json.listOf('lines', (item) => item)) line.strOr('code', ''): line};
    Money lineAmount(String code) => lines[code]?.moneyOrNull('amount') ?? Money.zero();
    final minimumOffer = json.moneyOrNull('minimumOffer');
    final maximumOffer = json.moneyOrNull('maximumOffer');
    return FareEstimate(
      baseFare: lineAmount('base_fare'),
      distanceKm: json.numOrNull('distanceKm') ?? 0,
      distanceFare: lineAmount('distance'),
      discount: lineAmount('discount'),
      boost: lineAmount('boost'),
      total: json.money('total'),
      ratePerKm: json.objectOrNull('rideClass')?.moneyOrNull('perKmRate'),
      hours: json.intOrNull('hours'),
      hourlyRate: json.moneyOrNull('hourlyRate'),
      meetGreetFee: lines['meet_greet']?.moneyOrNull('amount'),
      quoteId: json.strOrNull('quoteId'),
      pricing: pricing,
      fairFare: minimumOffer == null || maximumOffer == null ? null : FairFareRange(min: minimumOffer, max: maximumOffer),
    );
  }

  final Money baseFare;
  final num distanceKm;
  final Money distanceFare;
  final Money discount;
  final Money boost;
  final Money total;
  final Map<PricingOption, Money> pricing;
  final Money? ratePerKm;
  final int? hours;
  final Money? hourlyRate;
  final Money? meetGreetFee;
  final String? quoteId;
  final FairFareRange? fairFare;

  Money adjustmentFor(PricingOption option) => (pricing[option] ?? total) - total;
}

enum FairFareProblem {
  tooLow,
  tooHigh;

  String messageFor(FairFareRange range) => switch (this) {
    tooLow => 'Offer at least ${range.min.format()} so drivers say yes',
    tooHigh => 'That’s above Standard. Offer up to ${range.max.format()}',
  };
}

class FairFareRange {
  const FairFareRange({required this.min, required this.max});

  factory FairFareRange.fromJson(JsonReader json) => FairFareRange(min: json.money('min'), max: json.money('max'));

  final Money min;
  final Money max;

  FairFareProblem? problemFor(Money offer) {
    if (offer < min) return FairFareProblem.tooLow;
    if (offer > max) return FairFareProblem.tooHigh;
    return null;
  }
}

enum RoutePoint { pickup, stop, dropoff }

class RouteEdit {
  const RouteEdit.pickup() : point = RoutePoint.pickup, stopIndex = null;

  const RouteEdit.dropoff() : point = RoutePoint.dropoff, stopIndex = null;

  const RouteEdit.stop([this.stopIndex]) : point = RoutePoint.stop;

  final RoutePoint point;
  final int? stopIndex;
}
