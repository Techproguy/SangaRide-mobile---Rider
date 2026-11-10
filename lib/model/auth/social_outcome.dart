import 'package:sanga_ride_core/sanga_ride_core.dart' show SocialCredential, SocialSignupRequired;

class SocialPrefill {
  const SocialPrefill({this.firstName, this.lastName, this.email, this.signupToken});

  factory SocialPrefill.of(SocialCredential credential, SocialSignupRequired reply) => SocialPrefill(
    firstName: reply.firstName ?? credential.firstName,
    lastName: reply.lastName ?? credential.lastName,
    email: reply.email ?? credential.email,
    signupToken: reply.signupToken,
  );

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? signupToken;
}

sealed class SocialOutcome {
  const SocialOutcome();
}

final class SocialSignedIn extends SocialOutcome {
  const SocialSignedIn();
}

final class SocialNeedsSignUp extends SocialOutcome {
  const SocialNeedsSignUp(this.prefill);

  final SocialPrefill prefill;
}

final class SocialStopped extends SocialOutcome {
  const SocialStopped();
}
