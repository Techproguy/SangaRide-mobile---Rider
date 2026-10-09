import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> dialNumber(String number) async {
  final isLaunched = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!isLaunched) {
    SangaToast.show('We couldn’t open your phone app. Dial $number to reach them.', tone: SangaToastTone.error);
  }
}
