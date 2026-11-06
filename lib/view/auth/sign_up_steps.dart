import 'package:sanga_ride/core/services/me_state.dart';

enum RiderSignUpStep {
  details,
  verify,
  aboutYou,
  selfie,
  home;

  static RiderSignUpStep fromName(String? name) =>
      values.firstWhere((step) => step.name == name, orElse: () => details);

  static RiderSignUpStep fromOnboarding(OnboardingStep step) => switch (step) {
    OnboardingStep.aboutYou => aboutYou,
    OnboardingStep.selfie => selfie,
    OnboardingStep.homePlace => home,
  };
}
