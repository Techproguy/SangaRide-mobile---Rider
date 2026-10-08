import 'package:sanga_ride/model/ride/ride_match.dart';
import 'package:sanga_ride/model/ride/ride_request.dart';
import 'package:sanga_ride/model/trip/wrapup/payment.dart';

class ReceiptPlace {
  const ReceiptPlace({required this.name, required this.address});

  factory ReceiptPlace.fromJson(Map<String, dynamic> json) =>
      ReceiptPlace(name: json['name'] as String, address: json['address'] as String);

  final String name;
  final String address;
}

class ReceiptLine {
  const ReceiptLine({required this.key, required this.label, required this.amount});

  factory ReceiptLine.fromJson(Map<String, dynamic> json) =>
      ReceiptLine(key: json['key'] as String, label: json['label'] as String, amount: (json['amount'] as num).toInt());

  final String key;
  final String label;
  final int amount;
}

class ReceiptPayment {
  const ReceiptPayment({required this.method, this.last4});

  factory ReceiptPayment.fromJson(Map<String, dynamic> json) =>
      ReceiptPayment(method: PaymentMethod.fromCode(json['method'] as String), last4: json['last4'] as String?);

  final PaymentMethod method;
  final String? last4;

  String get label => method == PaymentMethod.card && last4 != null ? '•••• $last4' : method.label;
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
  });

  factory TripReceipt.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as Map?;
    return TripReceipt(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      pickup: ReceiptPlace.fromJson(Map<String, dynamic>.from(json['pickup'] as Map)),
      dropoff: ReceiptPlace.fromJson(Map<String, dynamic>.from(json['dropoff'] as Map)),
      stops: [for (final stop in json['stops'] as List) ReceiptPlace.fromJson(Map<String, dynamic>.from(stop as Map))],
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      lines: [for (final line in json['lines'] as List) ReceiptLine.fromJson(Map<String, dynamic>.from(line as Map))],
      total: (json['total'] as num).toInt(),
      paidWith: ReceiptPayment.fromJson(Map<String, dynamic>.from(json['paidWith'] as Map)),
      paidAt: DateTime.parse(json['paidAt'] as String).toLocal(),
      driver: OfferDriver.fromJson(Map<String, dynamic>.from(json['driver'] as Map)),
      vehicle: DriverVehicle.fromJson(Map<String, dynamic>.from(json['vehicle'] as Map)),
      category: RideCategory.values.asNameMap()[json['category']] ?? RideCategory.go,
      ratedStars: rating == null ? null : (rating['stars'] as num).toInt(),
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
  connection('connection', 'We couldn’t load your receipt', 'Check your connection and try again.');

  const ReceiptFailure(this.code, this.title, this.message);

  final String code;
  final String title;
  final String message;

  bool get canRetry => this != notFound;

  static ReceiptFailure fromCode(String? code) =>
      values.firstWhere((failure) => failure.code == code, orElse: () => connection);
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
