part of 'ride_request_controller.dart';

extension RideRequestPayload on RideRequestController {
  Map<String, dynamic> get bookingJson => {
    'tripType': tripType.code,
    'timing': timing.name,
    if (scheduledAt case final at?) ...{'scheduledFor': at.toUtc().toIso8601String(), 'timezone': BookingZone.of(at)},
    if (repeatRule case final rule?) 'repeat': rule.toJson(),
    if (tripType == TripType.hourly) ...{
      'hourlyDurationMin': hours * Duration.minutesPerHour,
      'stayWithMe': staysWithRider,
      'hourly': {'durationMin': hours * Duration.minutesPerHour, 'stayWithMe': staysWithRider},
    },
    if (tripType == TripType.intercity) ...{
      'fromCityId': fromCity?.id,
      'toCityId': toCity?.id,
      'intercity': {
        'fromCityId': fromCity?.id,
        'toCityId': toCity?.id,
        'departAt': ?scheduledAt?.toUtc().toIso8601String(),
      },
    },
    if (returnAt case final at? when tripType.needsReturn) ...{
      'returnAt': at.toUtc().toIso8601String(),
      'roundTrip': {
        'departAt': (scheduledAt ?? DateTime.now()).toUtc().toIso8601String(),
        'returnAt': at.toUtc().toIso8601String(),
      },
    },
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
      'proposedFare': booking.fare.toJson(),
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
      'quoteId': ?estimate?.quoteId,
      'rideClassId': option.id,
      'pickup': pickup.toLocationJson(),
      'stops': [for (final stop in stops) stop.toLocationJson()],
      'dropoff': dropoff.toLocationJson(),
      'preferences': preferences.toJson(),
      'pricingOption': pricing.code,
      if (pricing == PricingOption.fairFare) 'offeredFare': price.major,
      ..._whoForJson(Get.find<RideForController>().rideFor),
      ...bookingJson,
    };
  }

  Future<Map<String, dynamic>?> lockedRequestPayload() async {
    final payload = requestPayload();
    if (payload == null || tripType == TripType.delivery) return payload;
    final terms = {...payload}..remove('quoteId');
    final signature = jsonEncode(terms);
    if (_lockedTerms != signature) {
      final quoteId = await _quoteFor(terms);
      if (quoteId == null) return payload;
      _lockedTerms = signature;
      _lockedQuoteId = quoteId;
    }
    return {...payload, 'quoteId': _lockedQuoteId};
  }

  void forgetLockedQuote() {
    _lockedTerms = null;
    _lockedQuoteId = null;
  }

  Future<String?> _quoteFor(Map<String, dynamic> terms) async {
    try {
      final response = await _api.post(AppEndpoints.rideEstimate, data: terms, suppressErrorToast: true);
      return JsonReader.of(response.data).objectOrNull('data')?.strOrNull('quoteId');
    } catch (e) {
      log('quote lock failed: $e');
      return null;
    }
  }

  Map<String, dynamic> _whoForJson(RideFor rideFor) => switch (rideFor) {
    RideForMe() => {'bookedFor': 'self'},
    RideForSomeone(:final passenger) => {'bookedFor': 'other', 'passenger': passenger.toJson()},
    RideForFamily(:final member) => {'bookedFor': 'family', 'familyMemberId': member.id},
    RideForBusiness(:final profile, :final purpose, :final note) => {
      'bookedFor': 'business',
      'business': {'groupId': profile.id, 'purpose': purpose, 'note': ?note},
    },
  };

  Future<ScheduleOutcome?> scheduleBooking() async {
    if (isScheduling || !isScheduledBooking) return null;
    _isScheduling.value = true;
    try {
      final payload = await lockedRequestPayload();
      if (payload == null) return const ScheduleRejected(BookingProblem.unknown);
      final mutation = _scheduleMutationFor(payload);
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
    if (problem == BookingProblem.quoteExpired) {
      _estimate.value = null;
      forgetLockedQuote();
    }
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
          AppEndpoints.rideRequests,
          data: payload,
          key: key,
          suppressErrorToast: true,
        );
        return ScheduledBooking.fromJson(response.dataMap);
      },
    );
  }
}
