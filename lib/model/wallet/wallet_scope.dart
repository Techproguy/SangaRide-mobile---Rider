class WalletScope {
  const WalletScope.personal() : groupId = null;

  const WalletScope.group(String this.groupId);

  final String? groupId;

  bool get isGroup => groupId != null;

  String? get tag => groupId == null ? null : 'wallet:$groupId';

  @override
  bool operator ==(Object other) => other is WalletScope && other.groupId == groupId;

  @override
  int get hashCode => groupId.hashCode;
}
