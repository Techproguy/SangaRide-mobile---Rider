import 'package:sanga_ride_core/sanga_ride_core.dart' show SocialCredential;

class SocialPrefill {
  const SocialPrefill({this.firstName, this.lastName, this.email});

  factory SocialPrefill.of(SocialCredential credential) =>
      SocialPrefill(firstName: credential.firstName, lastName: credential.lastName, email: credential.email);

  final String? firstName;
  final String? lastName;
  final String? email;
}

sealed class SocialOutcome {
  const SocialOutcome();
}

final class SocialSignedIn extends SocialOutcome {
  const SocialSignedIn({required this.isNewUser});

  final bool isNewUser;
}

final class SocialNeedsSignUp extends SocialOutcome {
  const SocialNeedsSignUp(this.prefill);

  final SocialPrefill prefill;
}

final class SocialStopped extends SocialOutcome {
  const SocialStopped();
}
