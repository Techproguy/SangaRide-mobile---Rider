import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/constants.dart';
import 'package:sanga_ride/core/services/auth_config.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show LegalLinks;
import 'package:sanga_ride_ui/sanga_ride_ui.dart';
import 'package:url_launcher/url_launcher.dart';

enum SangaLegal {
  terms,
  privacy,
  guidelines;

  String? get serverUrl => switch (this) {
    SangaLegal.terms => LegalLinks.current.terms,
    SangaLegal.privacy => LegalLinks.current.privacy,
    SangaLegal.guidelines => LegalLinks.current.communityGuidelines,
  };

}

Future<void> openSangaLegal(BuildContext context, SangaLegal document) async {
  if (document.serverUrl == null) await AuthConfig.loadServerConfig(Get.find<ApiService>());
  final url = document.serverUrl;
  if (url == null) {
    SangaToast.show(SangaCommonCopy.unreachableTryAgain, tone: SangaToastTone.error);
    return;
  }
  await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
}

Widget buildSangaLegalSection(BuildContext context) => SangaLegalSection(
  appName: SangaConstants.appName,
  onOpenTerms: () => openSangaLegal(context, SangaLegal.terms),
  onOpenPrivacy: () => openSangaLegal(context, SangaLegal.privacy),
);
