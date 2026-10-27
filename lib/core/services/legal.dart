import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:url_launcher/url_launcher.dart';

enum SangaLegal {
  terms('Terms of Service', Icons.gavel_rounded, 'https://sangatechnologies.com/legal/terms', isPublished: false),
  privacy('Privacy Policy', Icons.privacy_tip_outlined, 'https://sangatechnologies.com/privacy-policy/'),
  guidelines(
    'Community guidelines',
    Icons.groups_outlined,
    'https://sangatechnologies.com/legal/community-guidelines',
    isPublished: false,
  );

  const SangaLegal(this.label, this.icon, this.url, {this.isPublished = true});

  final String label;
  final IconData icon;
  final String url;
  final bool isPublished;

  static List<SangaLegal> get published => [
    for (final document in values)
      if (document.isPublished && document.url.isNotEmpty) document,
  ];
}

Future<void> openSangaLegal(BuildContext context, SangaLegal document) async {
  await launchUrl(Uri.parse(document.url), mode: LaunchMode.inAppBrowserView);
}

List<SangaLegalLink> sangaLegalLinks(BuildContext context) => [
  for (final document in SangaLegal.published)
    SangaLegalLink(label: document.label, icon: document.icon, onTap: () => openSangaLegal(context, document)),
];
