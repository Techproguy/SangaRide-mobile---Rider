class CancelCopy {
  const CancelCopy._(this.noun);

  static const CancelCopy ride = CancelCopy._('ride');
  static const CancelCopy delivery = CancelCopy._('delivery');

  static CancelCopy of({required bool isDelivery}) => isDelivery ? delivery : ride;

  static const String continueLabel = 'Continue';
  static const String whyCancelling = 'Why are you cancelling?';
  static const String tellUsWhatHappened = 'Tell us what happened';
  static const String fewWordsIsPlenty = 'A few words is plenty';
  static const String getHelpFirst = 'If you feel unsafe right now, get help first';
  static const String fareBreakdown = 'Fare breakdown';
  static const String cancellationFee = 'Cancellation fee';
  static const String free = 'Free';
  static const String paymentMethod = 'Payment method';
  static const String notSetYet = 'Not set yet';
  static const String refund = 'Refund';
  static const String reason = 'Reason';
  static const String notApplicable = 'Not applicable';
  static const String cannotUndo = 'You can’t undo this.';
  static const String gotIt = 'Got it';

  static String feeChanged(String before, String after) =>
      'The fee changed from $before to $after. Take a look before you cancel.';

  static String refundTo(String amount, String destination) => '$amount to your $destination';

  final String noun;

  String get title => 'Cancel $noun';

  String titleWithFee(String fee) => '$title · $fee';

  String get keepLabel => 'Keep my $noun';

  String get confirmTitle => 'Cancel this $noun?';

  String get confirmAction => 'Yes, cancel $noun';

  String get confirmKeep => 'Keep $noun';

  String get doneTitle => '${noun[0].toUpperCase()}${noun.substring(1)} cancelled';
}
