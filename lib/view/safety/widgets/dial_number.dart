import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> dialNumber(String number) async {
  final isLaunched = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!isLaunched) Toast.error('We couldn’t open your phone app.');
}
