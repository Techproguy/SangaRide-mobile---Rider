enum TripType {
  oneWay('One way', 'Go to a destination'),
  roundTrip('Round trip', 'Go there and come straight back');

  const TripType(this.label, this.description);

  final String label;
  final String description;
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

  factory RideOption.fromJson(Map<String, dynamic> json) => RideOption(
    id: json['id'] as String,
    category: RideCategory.values.byName(json['category'] as String),
    name: json['name'] as String,
    description: json['description'] as String,
    seats: json['seats'] as String,
    pricePerKm: json['pricePerKm'] as num,
  );

  final String id;
  final RideCategory category;
  final String name;
  final String description;
  final String seats;
  final num pricePerKm;
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
  later('Later', 'Schedule a ride');

  const RideTiming(this.label, this.description);

  final String label;
  final String description;
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
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) => FareEstimate(
    baseFare: json['baseFare'] as num,
    distanceKm: json['distanceKm'] as num,
    distanceFare: json['distanceFare'] as num,
    discount: json['discount'] as num,
    boost: json['boost'] as num,
    total: json['total'] as num,
    pricing: {
      for (final MapEntry(:key, :value) in (json['pricing'] as Map).entries)
        PricingOption.values.byName(key as String): value as num,
    },
  );

  final num baseFare;
  final num distanceKm;
  final num distanceFare;
  final num discount;
  final num boost;
  final num total;
  final Map<PricingOption, num> pricing;

  num adjustmentFor(PricingOption option) => (pricing[option] ?? total) - total;
}

enum RoutePoint { pickup, stop, dropoff }

class RouteEdit {
  const RouteEdit.pickup() : point = RoutePoint.pickup, stopIndex = null;

  const RouteEdit.dropoff() : point = RoutePoint.dropoff, stopIndex = null;

  const RouteEdit.stop([this.stopIndex]) : point = RoutePoint.stop;

  final RoutePoint point;
  final int? stopIndex;
}
