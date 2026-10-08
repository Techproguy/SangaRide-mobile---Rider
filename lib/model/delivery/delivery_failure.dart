enum DeliveryFailure {
  fileTooLarge('file_too_large', 'That photo is too big', 'Pick a smaller one or snap it again.'),
  unsupportedType('unsupported_type', 'We can’t use that file', 'Choose a JPG or PNG photo instead.'),
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
    'quote_expired',
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
  connection('connection', 'We couldn’t reach the server', 'Check your connection and give it another go.'),
  unknown('unknown', 'Something went wrong', 'Give it another go in a moment.');

  const DeliveryFailure(this.code, this.title, this.message, {this.opensSettings = false});

  final String code;
  final String title;
  final String message;
  final bool opensSettings;

  bool get isRetriable => this == connection || this == unknown;

  bool get isRejection => this == quoteExpired || this == itemProhibited || this == invalidRecipientPhone;

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

  static DeliveryFailure fromCode(String? code) =>
      values.firstWhere((failure) => failure.code == code, orElse: () => unknown);
}
