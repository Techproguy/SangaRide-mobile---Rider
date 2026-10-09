import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride/model/trip/trip_delivery.dart';
import 'package:sanga_ride/model/trip/wrapup/payment.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class ReceiptPlace {
  const ReceiptPlace({required this.name, required this.address});

  factory ReceiptPlace.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return ReceiptPlace(name: reader.str('name'), address: reader.strOr('address', ''));
  }

  final String name;
  final String address;
}

class ReceiptLine {
  const ReceiptLine({required this.key, required this.label, required this.amount});

  factory ReceiptLine.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return ReceiptLine(key: reader.strOr('key', ''), label: reader.str('label'), amount: reader.integer('amount'));
  }

  final String key;
  final String label;
  final int amount;
}

class ReceiptPayment {
  const ReceiptPayment({required this.method, this.last4, this.group});

  factory ReceiptPayment.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final group = reader.objectOrNull('group');
    return ReceiptPayment(
      method: PaymentMethod.tryFromCode(reader.strOrNull('method')),
      last4: reader.strOrNull('last4'),
      group: group == null ? null : _groupOf(group),
    );
  }

  static PaymentGroup? _groupOf(JsonReader reader) {
    try {
      return PaymentGroup.fromJson(reader.raw);
    } catch (_) {
      return null;
    }
  }

  final PaymentMethod? method;
  final String? last4;
  final PaymentGroup? group;

  String get label => switch ((method, group)) {
    (PaymentMethod.card, _) when last4 != null => '•••• $last4',
    (PaymentMethod.groupWallet, final group?) => '${group.name} wallet',
    (final PaymentMethod method?, _) => method.label,
    _ => 'Paid',
  };
}

class ReceiptDelivery {
  const ReceiptDelivery({
    required this.tier,
    required this.itemName,
    required this.recipientName,
    required this.deliveredAt,
    required this.proofPhotoUrl,
  });

  factory ReceiptDelivery.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return ReceiptDelivery(
      tier: reader.strOr('tier', 'standard'),
      itemName: reader.strOr('itemName', ''),
      recipientName: reader.strOr('recipientName', ''),
      deliveredAt: reader.timeOrNull('deliveredAt')?.toLocal(),
      proofPhotoUrl: reader.strOrNull('proofPhotoUrl'),
    );
  }

  final String tier;
  final String itemName;
  final String recipientName;
  final DateTime? deliveredAt;
  final String? proofPhotoUrl;

  String get tierLabel => DeliveryTier.labelOf(tier);
}

class TripReceipt {
  const TripReceipt({
    required this.id,
    required this.tripId,
    required this.pickup,
    required this.dropoff,
    required this.stops,
    required this.distanceKm,
    required this.durationMinutes,
    required this.lines,
    required this.total,
    required this.paidWith,
    required this.paidAt,
    required this.driver,
    required this.vehicle,
    required this.category,
    required this.ratedStars,
    this.delivery,
  });

  factory TripReceipt.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final delivery = reader.objectOrNull('delivery');
    return TripReceipt(
      id: reader.str('id'),
      tripId: reader.str('tripId'),
      pickup: ReceiptPlace.fromJson(reader.object('pickup').raw),
      dropoff: ReceiptPlace.fromJson(reader.object('dropoff').raw),
      stops: reader.listOf('stops', (stop) => ReceiptPlace.fromJson(stop.raw)),
      distanceKm: reader.doubleOr('distanceKm', 0),
      durationMinutes: reader.intOr('durationMinutes', 0),
      lines: reader.listOf('lines', (line) => ReceiptLine.fromJson(line.raw)),
      total: reader.integer('total'),
      paidWith: ReceiptPayment.fromJson(reader.objectOrNull('paidWith')?.raw ?? const {}),
      paidAt: reader.timeOrNull('paidAt')?.toLocal() ?? DateTime.now(),
      driver: OfferDriver.fromJson(reader.raw['driver']),
      vehicle: DriverVehicle.fromJson(reader.raw['vehicle']),
      category: RideCategory.values.asNameMap()[reader.strOrNull('category')] ?? RideCategory.go,
      ratedStars: reader.objectOrNull('rating')?.intOrNull('stars'),
      delivery: delivery == null ? null : ReceiptDelivery.fromJson(delivery.raw),
    );
  }

  final String id;
  final String tripId;
  final ReceiptPlace pickup;
  final ReceiptPlace dropoff;
  final List<ReceiptPlace> stops;
  final double distanceKm;
  final int durationMinutes;
  final List<ReceiptLine> lines;
  final int total;
  final ReceiptPayment paidWith;
  final DateTime paidAt;
  final OfferDriver driver;
  final DriverVehicle vehicle;
  final RideCategory category;
  final int? ratedStars;
  final ReceiptDelivery? delivery;

  bool get isDelivery => delivery != null;

  bool get isRated => ratedStars != null;

  String get distanceLabel {
    final rounded = distanceKm.toStringAsFixed(1);
    return '${rounded.endsWith('.0') ? rounded.substring(0, rounded.length - 2) : rounded} km';
  }

  String get durationLabel => durationMinutes == 1 ? '1 minute' : '$durationMinutes minutes';
}

enum ReceiptFailure {
  notReady('payment_pending', 'Your receipt isn’t ready yet', 'It shows up as soon as your payment is confirmed.'),
  notFound('trip_not_found', 'We can’t find this receipt', 'This trip may have been removed. Head back and try again.'),
  connection('connection', 'We couldn’t load your receipt', 'Check your connection and try again.'),
  unknown('unknown', 'Something went wrong', 'Something went wrong on our side. Try again in a moment.');

  const ReceiptFailure(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  bool get canRetry => this != notFound;

  static ReceiptFailure fromCode(String? code) => enumByCode(values, code, (failure) => failure.code, unknown);

  static ReceiptFailure of(Object error) {
    if (error is ApiException && error.kind == ApiFailureKind.rejected) return fromCode(error.code);
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => connection,
      _ => unknown,
    };
  }
}

sealed class ReceiptState {
  const ReceiptState();
}

final class ReceiptLoading extends ReceiptState {
  const ReceiptLoading();
}

final class ReceiptLoaded extends ReceiptState {
  const ReceiptLoaded(this.receipt);

  final TripReceipt receipt;
}

final class ReceiptFailed extends ReceiptState {
  const ReceiptFailed(this.reason);

  final ReceiptFailure reason;
}
