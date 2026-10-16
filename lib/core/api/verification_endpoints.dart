import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class VerificationEndpoints {
  static const String _verification = '/verification';

  static const String status = _verification;
  static const String documents = '$_verification/documents';
  static const String documentFiles = '$_verification/documents/files';
  static const String documentFile = '$_verification/documents/files/:id';
  static const String selfie = '$_verification/selfie';
  static const String uploads = '/uploads';

  static String documentFileOf(String id) => fillPath(documentFile, {'id': id});
}
