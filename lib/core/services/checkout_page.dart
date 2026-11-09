import 'package:url_launcher/url_launcher.dart';

Future<bool> openCheckoutPage(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } on Object {
    return false;
  }
}
