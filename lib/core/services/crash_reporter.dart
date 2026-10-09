import 'dart:developer';

import 'package:flutter/foundation.dart';

abstract interface class CrashReporter {
  void record(Object error, StackTrace? stack, {required String source});
}

class ConsoleCrashReporter implements CrashReporter {
  const ConsoleCrashReporter();

  @override
  void record(Object error, StackTrace? stack, {required String source}) {
    log('[$source] $error', name: 'CrashReporter', error: error, stackTrace: stack);
  }
}

abstract final class CrashReporting {
  static CrashReporter reporter = const ConsoleCrashReporter();

  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      reporter.record(details.exception, details.stack, source: 'flutter');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      reporter.record(error, stack, source: 'platform');
      return true;
    };
  }

  static void recordZoneError(Object error, StackTrace stack) {
    reporter.record(error, stack, source: 'zone');
  }
}
