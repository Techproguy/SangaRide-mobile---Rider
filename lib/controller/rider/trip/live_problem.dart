import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class LiveProblem {
  static const String checking = 'We’re still checking. Give it a moment before you try again.';

  static bool get isOffline => ConnectionMonitor.current?.isOnline == false;

  static String messageOf(Object error) {
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => CommonCopy.offline,
      ProblemRejected(:final message) when message.isNotEmpty => message,
      _ => CommonCopy.serverTrouble,
    };
  }

  static void toastOffline() => SangaToast.show(CommonCopy.offline, tone: SangaToastTone.error);

  static void toast(Object error) => SangaToast.show(messageOf(error), tone: SangaToastTone.error);
}
