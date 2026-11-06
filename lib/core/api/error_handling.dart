import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/model/account/account_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart' show SangaAuthCopy, SangaCommonCopy;

export 'package:sanga_ride_core/sanga_ride_core.dart' show ApiException, ApiFailureKind;

extension ApiExceptionStatus on ApiException {
  bool get isNotFound => statusCode == 404;

  bool get isGone => statusCode == 404 || statusCode == 410;
}

abstract final class ApiFailureCopy {
  static const String offline = 'You are offline. Check your connection and try again.';
  static const String timedOut = 'That took too long. Give it another go.';
  static const String outcomeUnknown = 'We did not hear back in time. Check before you try again.';
  static const String server = SangaCommonCopy.serverTrouble;
  static const String unexpectedReply = 'We got a reply we could not read. Try again in a moment.';

  static String? toastFor(ApiException error, {required bool isAuthPath}) {
    return switch (error.kind) {
      ApiFailureKind.offline => offline,
      ApiFailureKind.timeout => timedOut,
      ApiFailureKind.noResponse => error.outcomeUnknown ? outcomeUnknown : timedOut,
      ApiFailureKind.server => error.outcomeUnknown ? outcomeUnknown : server,
      ApiFailureKind.parse => unexpectedReply,
      ApiFailureKind.rejected => _rejection(error, isAuthPath: isAuthPath),
      ApiFailureKind.unauthorized => isAuthPath && error.message.isNotEmpty ? rejectionMessage(error) : null,
    };
  }

  static String? _rejection(ApiException error, {required bool isAuthPath}) {
    final isSilent = error.statusCode == 403 && !isAuthPath;
    if (isSilent || (error.message.isEmpty && error.code == null)) return null;
    if (error.isNotFound) return SangaCommonCopy.notFound;
    return rejectionMessage(error);
  }

  static String rejectionMessage(ApiException error) {
    final conflict = AccountProblem.conflictOf(error);
    if (conflict != null) return conflict.message;
    final problem = AccountProblem.of(error);
    if (problem != AccountProblem.unknown && problem != AccountProblem.connection) return problem.message;
    return switch (error.code) {
      ServerCode.rateLimited ||
      ServerCode.tooManyAttempts ||
      ServerCode.otpTooManyAttempts ||
      ServerCode.otpTooSoon => SangaCommonCopy.rateLimitedWait,
      ServerCode.accountSuspended => SangaCommonCopy.accountOnHold,
      ServerCode.sessionRevoked || ServerCode.tokenExpired => SangaCommonCopy.sessionEnded,
      ServerCode.accountNotFound => SangaAuthCopy.noAccountForNumber,
      ServerCode.validationFailed => _validationMessage(error),
      _ => _byStatus(error),
    };
  }

  static String _byStatus(ApiException error) => switch (error.statusCode) {
    429 => SangaCommonCopy.rateLimitedWait,
    410 => SangaCommonCopy.expiredStartOver,
    400 || 422 => SangaCommonCopy.detailsDontLookRight,
    _ => SangaCommonCopy.rejectedTryAgain,
  };

  static String _validationMessage(ApiException error) {
    final errors = error.data['errors'];
    final first = errors is List && errors.isNotEmpty && errors.first is Map ? errors.first as Map : const {};
    return switch (first['field']) {
      'email' => AccountProblem.invalidEmail.message,
      'phone' => AccountProblem.invalidPhone.message,
      'firstName' || 'lastName' => AccountProblem.nameRequired.message,
      _ => SangaCommonCopy.detailsDontLookRight,
    };
  }
}
