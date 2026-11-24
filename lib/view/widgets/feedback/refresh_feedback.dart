import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> refreshWithFeedback(Future<bool> Function() reload) async {
  if (await reload()) return;
  SangaToast.show(CommonCopy.refreshFailed, tone: SangaToastTone.error);
}
