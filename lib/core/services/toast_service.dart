import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class Toast {
  static void success(String message, {Duration? duration}) => _show(message, SangaToastTone.success, duration);

  static void error(String message, {Duration? duration}) => _show(message, SangaToastTone.error, duration);

  static void warning(String message, {Duration? duration}) => _show(message, SangaToastTone.warning, duration);

  static void info(String message, {Duration? duration}) => _show(message, SangaToastTone.info, duration);

  static void dismiss() => SangaToast.dismiss();

  static void _show(String message, SangaToastTone tone, Duration? duration) {
    SangaToast.show(message, tone: tone, duration: duration);
  }
}
