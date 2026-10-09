import 'package:sanga_ride_core/sanga_ride_core.dart';

export 'package:sanga_ride_core/sanga_ride_core.dart' show ApiException, ApiFailureKind;

abstract final class ApiFailureCopy {
  static const String offline = 'You are offline. Check your connection and try again.';
  static const String timedOut = 'That took too long. Give it another go.';
  static const String outcomeUnknown = 'We did not hear back in time. Check before you try again.';
  static const String server = 'Something went wrong on our side. Try again in a moment.';
  static const String unexpectedReply = 'We got a reply we could not read. Try again in a moment.';

  static String? toastFor(ApiException error, {required bool isAuthPath}) {
    return switch (error.kind) {
      ApiFailureKind.offline => offline,
      ApiFailureKind.timeout => timedOut,
      ApiFailureKind.noResponse => error.outcomeUnknown ? outcomeUnknown : timedOut,
      ApiFailureKind.server => error.outcomeUnknown ? outcomeUnknown : server,
      ApiFailureKind.parse => unexpectedReply,
      ApiFailureKind.rejected => _rejection(error, isAuthPath: isAuthPath),
      ApiFailureKind.unauthorized => isAuthPath && error.message.isNotEmpty ? error.message : null,
    };
  }

  static String? _rejection(ApiException error, {required bool isAuthPath}) {
    final isSilent = error.statusCode == 403 && !isAuthPath;
    if (isSilent || error.message.isEmpty) return null;
    return error.message;
  }
}
