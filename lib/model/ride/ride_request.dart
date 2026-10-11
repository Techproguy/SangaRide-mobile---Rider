import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum TripType {
  oneWay('One way', 'Go to a destination'),
  roundTrip('Round trip', 'Go there and come back'),
  hourly('Hourly', 'Keep a driver for a set time'),
  intercity('Intercity', 'Travel between cities'),
  airport('Airport', 'Get picked up from the airport'),
  delivery('Delivery', 'Send a package across town');

  const TripType(this.label, this.description);

  final String label;
  final String description;

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
    final category = RideCategory.values.asNameMap()[json.strOrNull('category')];
    if (category == null) throw JsonFormatError('Unknown ride category', json.raw['category']);
    return RideOption(
      id: json.str('id'),
      category: category,
      name: json.str('name'),
      description: json.strOr('description', ''),
      seats: json.strOr('seats', '1'),
      pricePerKm: json.money('pricePerKm'),
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
  standard('Standard', 'Our usual price for this trip', null),
  fairFare('Fair Fare', 'A little under the usual price', 'Fair Fare discount'),
  saver('Saver', 'The lowest price we offer', 'Saver discount'),
  priority('Priority', 'A bit above the usual price', 'Priority extra');

  const PricingOption(this.label, this.description, this.adjustmentLabel);

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
  });

  factory FareEstimate.fromJson(Object? body) {
    final json = JsonReader.of(body);
    final pricing = <PricingOption, Money>{};
    final rawPricing = json.objectOrNull('pricing')?.raw ?? const <String, dynamic>{};
    for (final MapEntry(:key, :value) in rawPricing.entries) {
      final option = PricingOption.values.asNameMap()[key];
      final amount = Money.tryParse(value);
      if (option != null && amount != null) pricing[option] = amount;
    }
    return FareEstimate(
      baseFare: json.money('baseFare'),
      distanceKm: json.numOrNull('distanceKm') ?? 0,
      distanceFare: json.money('distanceFare'),
      discount: json.money('discount'),
      boost: json.money('boost'),
      total: json.money('total'),
      ratePerKm: json.moneyOrNull('ratePerKm'),
      hours: json.intOrNull('hours'),
      hourlyRate: json.moneyOrNull('hourlyRate'),
      meetGreetFee: json.moneyOrNull('meetGreetFee'),
      quoteId: json.strOrNull('quoteId'),
      pricing: pricing,
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

  Money adjustmentFor(PricingOption option) => (pricing[option] ?? total) - total;
}

enum RoutePoint { pickup, stop, dropoff }

class RouteEdit {
  const RouteEdit.pickup() : point = RoutePoint.pickup, stopIndex = null;

  const RouteEdit.dropoff() : point = RoutePoint.dropoff, stopIndex = null;

  const RouteEdit.stop([this.stopIndex]) : point = RoutePoint.stop;

  final RoutePoint point;
  final int? stopIndex;
}
