part of 'ride_request_controller.dart';

extension RideRequestPayload on RideRequestController {
  Map<String, dynamic> get bookingJson => {
    'tripType': tripType.name,
    'timing': timing.name,
    if (scheduledAt case final at?) ...{'scheduledAt': at.toUtc().toIso8601String(), 'timezone': BookingZone.of(at)},
    if (repeatRule case final rule?) 'repeat': rule.toJson(),
    if (tripType == TripType.hourly) ...{'hours': hours, 'stayWithMe': staysWithRider},
    if (tripType == TripType.intercity) ...{'fromCityId': fromCity?.id, 'toCityId': toCity?.id},
    if (returnAt case final at? when tripType.needsReturn) 'returnAt': at.toUtc().toIso8601String(),
    if (airportBooking case final booking? when tripType == TripType.airport) 'airport': booking.toJson(),
    if (deliveryBooking case final booking? when tripType == TripType.delivery) 'delivery': booking.toJson(),
  };

  Map<String, dynamic>? _deliveryPayload() {
    final pickup = this.pickup;
    final dropoff = this.dropoff;
    final booking = deliveryBooking;
    if (pickup == null || dropoff == null || booking == null) return null;
    return {
      'pickup': pickup.toJson(),
      'stops': [for (final stop in stops) stop.toJson()],
      'dropoff': dropoff.toJson(),
      'rideFor': Get.find<RideForController>().rideFor.toJson(),
      'pricingMode': PricingOption.standard.name,
      'proposedFare': booking.fare,
      ...bookingJson,
    };
  }

  Map<String, dynamic>? requestPayload() {
    if (tripType == TripType.delivery) return _deliveryPayload();
    final pickup = this.pickup;
    final dropoff = this.dropoff;
    final option = this.option;
    final pricing = this.pricing;
    final price = this.price;
    if (pickup == null || dropoff == null || option == null || pricing == null || price == null) return null;
    return {
      'optionId': option.id,
      'pickup': pickup.toJson(),
      'stops': [for (final stop in stops) stop.toJson()],
      'dropoff': dropoff.toJson(),
      'preferences': preferences.toJson(),
      'rideFor': Get.find<RideForController>().rideFor.toJson(),
      'pricingMode': pricing.name,
      'proposedFare': price.round(),
      'quoteId': ?estimate?.quoteId,
      ...bookingJson,
    };
  }

  Future<ScheduleOutcome?> scheduleBooking() async {
    if (isScheduling || !isScheduledBooking) return null;
    final payload = requestPayload();
    if (payload == null) return const ScheduleRejected(BookingProblem.unknown);
    final mutation = _scheduleMutationFor(payload);
    _isScheduling.value = true;
    try {
      final result = await mutation.start();
      return switch (result) {
        MutationDone<ScheduledBooking>(:final value) => ScheduleSucceeded(value),
        MutationRejected<ScheduledBooking>(:final error) => _scheduleRejection(error),
        MutationFailed<ScheduledBooking>(:final error) => ScheduleRejected(BookingProblem.of(error)),
        MutationUnknown<ScheduledBooking>() => const ScheduleUnconfirmed(),
        MutationIdle<ScheduledBooking>() ||
        MutationRunning<ScheduledBooking>() ||
        MutationChecking<ScheduledBooking>() => const ScheduleUnconfirmed(),
      };
    } finally {
      _isScheduling.value = false;
    }
  }

  ScheduleOutcome _scheduleRejection(ApiException error) {
    final problem = BookingProblem.of(error);
    if (problem == BookingProblem.quoteExpired) _estimate.value = null;
    return ScheduleRejected(problem);
  }

  Mutation<ScheduledBooking> _scheduleMutationFor(Map<String, dynamic> payload) {
    final signature = jsonEncode(payload);
    final existing = _scheduleMutation;
    if (existing != null && _scheduleSignature == signature) return existing;
    existing?.dispose();
    _scheduleSignature = signature;
    return _scheduleMutation = Mutation<ScheduledBooking>(
      intent: IdempotencyIntent.scheduleRide,
      run: (key) async {
        final response = await _api.post(
          BookingEndpoints.scheduledRides,
          data: payload,
          key: key,
          suppressErrorToast: true,
        );
        return ScheduledBooking.fromJson(response.dataMap);
      },
    );
  }
}
