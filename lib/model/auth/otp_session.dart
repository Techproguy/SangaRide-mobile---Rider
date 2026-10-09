import 'package:sanga_ride_core/sanga_ride_core.dart';

class OtpSession {
  const OtpSession({required this.sentAt, required this.lifetime, required this.resendAfter});

  factory OtpSession.fromData(Object? data) {
    final json = JsonReader.of(data);
    return OtpSession(
      sentAt: DateTime.now(),
      lifetime: Duration(seconds: json.intOr('expiresInSeconds', fallbackLifetime.inSeconds)),
      resendAfter: Duration(seconds: json.intOr('resendInSeconds', fallbackResend.inSeconds)),
    );
  }

  static const Duration fallbackLifetime = Duration(minutes: 5);
  static const Duration fallbackResend = Duration(seconds: 60);

  final DateTime sentAt;
  final Duration lifetime;
  final Duration resendAfter;
}

sealed class OtpRequestResult {
  const OtpRequestResult();
}

final class OtpSent extends OtpRequestResult {
  const OtpSent(this.session);

  final OtpSession session;
}

final class OtpNotSent extends OtpRequestResult {
  const OtpNotSent(this.message);

  final String message;
}

enum AuthProblem {
  offline('You’re offline. Check your connection and try again.'),
  server('Something went wrong on our side. Try again in a moment.'),
  unknown('Something went wrong on our side. Try again in a moment.');

  const AuthProblem(this.message);

  final String message;

  static AuthProblem of(Object error) => switch (ProblemKind.of(error)) {
    ProblemOffline() => offline,
    ProblemServer() => server,
    _ => unknown,
  };
}
