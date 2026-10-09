class HistoryScope {
  const HistoryScope.personal() : groupId = null;

  const HistoryScope.group(String this.groupId);

  final String? groupId;

  bool get isGroup => groupId != null;

  String? get tag => groupId == null ? null : 'history:$groupId';
}
