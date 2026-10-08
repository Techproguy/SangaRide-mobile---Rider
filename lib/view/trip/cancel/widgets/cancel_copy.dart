class CancelCopy {
  const CancelCopy._(this.noun);

  static const CancelCopy ride = CancelCopy._('ride');
  static const CancelCopy delivery = CancelCopy._('delivery');

  static CancelCopy of({required bool isDelivery}) => isDelivery ? delivery : ride;

  final String noun;

  String get title => 'Cancel $noun';

  String get keepLabel => 'Keep my $noun';

  String get confirmTitle => 'Cancel this $noun?';

  String get confirmAction => 'Yes, cancel $noun';

  String get confirmKeep => 'Keep $noun';

  String get doneTitle => '${noun[0].toUpperCase()}${noun.substring(1)} cancelled';
}
