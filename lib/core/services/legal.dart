import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/services/auth_config.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show LegalLinks;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:url_launcher/url_launcher.dart';

enum SangaLegal {
  terms('Terms of Service', Icons.gavel_rounded),
  privacy('Privacy Policy', Icons.privacy_tip_outlined),
  guidelines('Community guidelines', Icons.groups_outlined);

  const SangaLegal(this.label, this.icon);

  static const String _siteRoot = 'https://sangatechnologies.com/';
  static const String _privacyPage = 'https://sangatechnologies.com/privacy-policy/';

  final String label;
  final IconData icon;

  String? get serverUrl => switch (this) {
    SangaLegal.terms => LegalLinks.current.terms,
    SangaLegal.privacy => LegalLinks.current.privacy,
    SangaLegal.guidelines => LegalLinks.current.communityGuidelines,
  };

  String get url => serverUrl ?? (this == SangaLegal.privacy ? _privacyPage : _siteRoot);
}

Future<void> openSangaLegal(BuildContext context, SangaLegal document) async {
  if (document.serverUrl == null) await AuthConfig.loadServerConfig(Get.find<ApiService>());
  await launchUrl(Uri.parse(document.url), mode: LaunchMode.inAppBrowserView);
}

List<SangaLegalLink> sangaLegalLinks(BuildContext context) => [
  for (final document in SangaLegal.values)
    SangaLegalLink(label: document.label, icon: document.icon, onTap: () => openSangaLegal(context, document)),
];
