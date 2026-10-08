import 'package:go_router/go_router.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/verification/verification_document_screen.dart';
import 'package:sanga_ride/view/verification/verification_screen.dart';
import 'package:sanga_ride/view/verification/verification_selfie_screen.dart';

abstract final class VerificationRoutes {
  static const String centre = '/verification';
  static const String selfie = '/verification/selfie';
  static const String document = '/verification/document';

  static final List<RouteBase> all = [
    GoRoute(path: centre, builder: (context, state) => const VerificationScreen()),
    GoRoute(path: selfie, builder: (context, state) => const VerificationSelfieScreen()),
    GoRoute(path: document, builder: (context, state) => const VerificationDocumentScreen()),
  ];

  static String itemOf(VerificationItem item) => switch (item.kind) {
    VerificationItemKind.document => document,
    VerificationItemKind.selfie => selfie,
  };
}
