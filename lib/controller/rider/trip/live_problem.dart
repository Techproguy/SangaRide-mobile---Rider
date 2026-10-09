import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class LiveProblem {
  static const String offline = 'You’re offline. Check your connection and give it another go.';
  static const String server = 'Something went wrong on our side. Try again in a moment.';
  static const String checking = 'We’re still checking. Give it a moment before you try again.';

  static bool get isOffline => ConnectionMonitor.current?.isOnline == false;

  static String messageOf(Object error) {
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => offline,
      ProblemRejected(:final message) when message.isNotEmpty => message,
      _ => server,
    };
  }

  static void toastOffline() => SangaToast.show(offline, tone: SangaToastTone.error);

  static void toast(Object error) => SangaToast.show(messageOf(error), tone: SangaToastTone.error);

  static bool needsChecking(Object error) => error is ApiException && error.outcomeUnknown;
}
