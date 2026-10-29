import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:url_launcher/url_launcher.dart';

enum SangaLegal {
  terms('Terms of Service', Icons.gavel_rounded, 'https://sangatechnologies.com/legal/terms'),
  privacy('Privacy Policy', Icons.privacy_tip_outlined, 'https://sangatechnologies.com/privacy-policy/'),
  guidelines('Community guidelines', Icons.groups_outlined, 'https://sangatechnologies.com/legal/community-guidelines');

  const SangaLegal(this.label, this.icon, this.url);

  final String label;
  final IconData icon;
  final String url;
}

Future<void> openSangaLegal(BuildContext context, SangaLegal document) async {
  await launchUrl(Uri.parse(document.url), mode: LaunchMode.inAppBrowserView);
}

List<SangaLegalLink> sangaLegalLinks(BuildContext context) => [
  for (final document in SangaLegal.values)
    SangaLegalLink(label: document.label, icon: document.icon, onTap: () => openSangaLegal(context, document)),
];
