enum DeleteReason {
  stoppedRiding('stopped_riding', 'I don’t ride anymore'),
  anotherApp('another_app', 'I use another app'),
  privacy('privacy', 'Privacy worries'),
  other('other', 'Something else');

  const DeleteReason(this.code, this.label);

  final String code;
  final String label;
}
