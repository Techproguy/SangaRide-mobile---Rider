import 'package:sanga_ride/model/verification/verification.dart';
import 'package:sanga_ride/model/verification/verification_problem.dart';

sealed class VerificationState {
  const VerificationState();

  Verification? get verificationOrNull => switch (this) {
    VerificationLoaded(:final verification) => verification,
    _ => null,
  };
}

final class VerificationLoading extends VerificationState {
  const VerificationLoading();
}

final class VerificationFailed extends VerificationState {
  const VerificationFailed(this.problem);

  final VerificationProblem problem;
}

final class VerificationLoaded extends VerificationState {
  const VerificationLoaded(this.verification);

  final Verification verification;
}
