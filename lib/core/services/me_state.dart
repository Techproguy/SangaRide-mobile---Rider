import 'package:sanga_ride_core/sanga_ride_core.dart';

enum OnboardingStep {
  aboutYou('about_you'),
  selfie('selfie'),
  homePlace('home');

  const OnboardingStep(this.code);

  final String code;

  static OnboardingStep? tryFromCode(String? code) {
    for (final step in values) {
      if (step.code == code) return step;
    }
    return null;
  }
}

class StatedTrip {
  const StatedTrip({required this.id, required this.status});

  final String id;
  final String status;
}

class StatedRideRequest {
  const StatedRideRequest({required this.id, required this.status});

  final String id;
  final String status;
}

class PendingTopUp {
  const PendingTopUp({required this.id, required this.scope, required this.status, this.groupId});

  final String id;
  final String scope;
  final String status;
  final String? groupId;
}

class MeState {
  const MeState({
    this.activeTrip,
    this.tripNeedingPayment,
    this.tripNeedingRating,
    this.activeRideRequest,
    this.activeSosId,
    this.pendingTopUps = const [],
    this.onboardingStep,
    this.serverTime,
  });

  factory MeState.fromEnvelope(Object? body) {
    final data = JsonReader.of(body).objectOrNull('data') ?? JsonReader.of(null);
    return MeState(
      activeTrip: _tryRead(
        data,
        'activeTrip',
        (item) => StatedTrip(id: item.str('id'), status: item.strOr('status', '')),
      ),
      tripNeedingPayment: data.strOrNull('tripNeedingPayment'),
      tripNeedingRating: data.strOrNull('tripNeedingRating'),
      activeRideRequest: _tryRead(
        data,
        'activeRideRequest',
        (item) => StatedRideRequest(id: item.str('id'), status: item.strOr('status', '')),
      ),
      activeSosId: _tryRead(data, 'activeSos', (item) => item.str('id')),
      pendingTopUps: data.listOf(
        'pendingTopUps',
        (item) => PendingTopUp(
          id: item.str('id'),
          scope: item.strOr('scope', 'personal'),
          status: item.strOr('status', ''),
          groupId: item.strOrNull('groupId'),
        ),
      ),
      onboardingStep: OnboardingStep.tryFromCode(data.objectOrNull('onboarding')?.strOrNull('nextStep')),
      serverTime: data.timeOrNull('serverTime'),
    );
  }

  final StatedTrip? activeTrip;
  final String? tripNeedingPayment;
  final String? tripNeedingRating;
  final StatedRideRequest? activeRideRequest;
  final String? activeSosId;
  final List<PendingTopUp> pendingTopUps;
  final OnboardingStep? onboardingStep;
  final DateTime? serverTime;

  static T? _tryRead<T>(JsonReader data, String key, T Function(JsonReader item) parse) {
    final item = data.objectOrNull(key);
    if (item == null) return null;
    try {
      return parse(item);
    } on JsonFormatError {
      return null;
    }
  }
}
