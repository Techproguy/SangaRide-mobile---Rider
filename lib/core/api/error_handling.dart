import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

export 'package:sanga_ride_core/sanga_ride_core.dart' show ApiException, ApiFailureKind;

extension ApiExceptionStatus on ApiException {
  bool get isNotFound => statusCode == 404;

  bool get isGone => statusCode == 404 || statusCode == 410;
}

abstract final class ApiFailureCopy {
  static const String offline = 'You are offline. Check your connection and try again.';
  static const String timedOut = 'That took too long. Give it another go.';
  static const String outcomeUnknown = 'We did not hear back in time. Check before you try again.';
  static const String server = CommonCopy.serverTrouble;
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
