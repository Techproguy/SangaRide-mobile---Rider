import 'package:sanga_ride/core/api/error_handling.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class LiveProblem {
  static const String checking = 'We’re still checking. Give it a moment before you try again.';

  static const String pinPending = 'Your PIN will show once your driver confirms you’re with them.';

  static bool get isOffline => ConnectionMonitor.current?.isOnline == false;

  static String messageOf(Object error) {
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => SangaCommonCopy.offlineAnotherGo,
      ProblemRejected() when error is ApiException => ApiFailureCopy.rejectionMessage(error),
      _ => SangaCommonCopy.serverTrouble,
    };
  }

  static void toastOffline() => SangaToast.show(SangaCommonCopy.offlineAnotherGo, tone: SangaToastTone.error);

  static void toast(Object error) => SangaToast.show(messageOf(error), tone: SangaToastTone.error);
}
