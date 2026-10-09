import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

enum SangaLegal {
  terms('https://sangatechnologies.com/legal/terms'),
  privacy('https://sangatechnologies.com/legal/privacy'),
  guidelines('https://sangatechnologies.com/legal/community-guidelines');

  const SangaLegal(this.url);

  final String url;
}

Future<void> openSangaLegal(BuildContext context, SangaLegal document) async {
  await launchUrl(Uri.parse(document.url), mode: LaunchMode.inAppBrowserView);
}
