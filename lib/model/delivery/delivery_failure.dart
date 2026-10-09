import 'package:sanga_ride/core/api/server_codes.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

enum DeliveryFailure {
  fileTooLarge(ServerCode.fileTooLarge, 'That photo is too big', 'Pick a smaller one or snap it again.'),
  unsupportedType(ServerCode.unsupportedType, 'We can’t use that file', 'Choose a JPG or PNG photo instead.'),
  unreadablePhoto('unreadable_photo', 'We couldn’t read that photo', 'Try another one or snap it again.'),
  cameraDenied(
    'camera_denied',
    'Camera is switched off',
    'Let Sanga use your camera in Settings to snap your package.',
    opensSettings: true,
  ),
  photosDenied(
    'photos_denied',
    'Photos are switched off',
    'Let Sanga see your photos in Settings to pick one.',
    opensSettings: true,
  ),
  cameraUnavailable(
    'camera_unavailable',
    'We can’t reach your camera',
    'Try again, or choose a photo from your gallery.',
  ),
  quoteExpired(
    ServerCode.quoteExpired,
    'Your price timed out',
    'We’ve fetched a fresh price for you. Have a look and go again.',
  ),
  itemProhibited(
    'item_prohibited',
    'We can’t carry that item',
    'Hazardous, illegal or restricted items are not allowed. Change what you’re sending to carry on.',
  ),
  invalidRecipientPhone(
    'invalid_recipient_phone',
    'That phone number looks off',
    'Check the recipient’s number so your driver can reach them.',
  ),
  connection('connection', CommonCopy.unreachableTitle, CommonCopy.connectionBody),
  unknown('unknown', CommonCopy.serverTitle, 'Give it another go in a moment.');

  const DeliveryFailure(this.code, this.title, this.message, {this.opensSettings = false});

  final String code;
  final String title;
  final String message;
  final bool opensSettings;

  bool get isRetriable => this == connection || this == unknown;

  String get actionLabel => switch (this) {
    quoteExpired => 'See new price',
    itemProhibited => 'Edit item',
    invalidRecipientPhone => 'Fix number',
    _ => 'Okay',
  };

  String messageWith(Map<String, dynamic> data) {
    final reason = reasonOf(data);
    return this == itemProhibited && reason != null ? reason : message;
  }

  static String? reasonOf(Map<String, dynamic> data) {
    final nested = data['data'];
    final reason = data['reason'] ?? (nested is Map ? nested['reason'] : null);
    return reason is String && reason.isNotEmpty ? reason : null;
  }

  static DeliveryFailure fromCode(String? code) => enumByCode(values, code, (failure) => failure.code, unknown);

  static DeliveryFailure of(Object error) {
    if (error is ApiException && error.kind == ApiFailureKind.rejected) return fromCode(error.code);
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => connection,
      _ => unknown,
    };
  }
}
