import 'package:sanga_ride_core/sanga_ride_core.dart';

class OwnedGroup {
  const OwnedGroup({required this.id, required this.name, required this.kind, required this.membersCount});

  factory OwnedGroup.fromReader(JsonReader reader) => OwnedGroup(
    id: reader.str('id'),
    name: reader.strOr('name', 'your group'),
    kind: reader.strOr('kind', 'family'),
    membersCount: reader.intOr('membersCount', 0),
  );

  final String id;
  final String name;
  final String kind;
  final int membersCount;
}

class DeletionPreview {
  const DeletionPreview({
    required this.graceDays,
    required this.walletBalance,
    required this.pendingTransfers,
    required this.ownedGroups,
    required this.hasActiveTrip,
  });

  factory DeletionPreview.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return DeletionPreview(
      graceDays: reader.intOr('graceDays', 30),
      walletBalance: reader.intOr('walletBalance', 0),
      pendingTransfers: reader.intOr('pendingTransfers', 0),
      ownedGroups: reader.listOf('ownedGroups', OwnedGroup.fromReader),
      hasActiveTrip: reader.boolOr('hasActiveTrip', false),
    );
  }

  final int graceDays;
  final int walletBalance;
  final int pendingTransfers;
  final List<OwnedGroup> ownedGroups;
  final bool hasActiveTrip;
}

sealed class DeletionPreviewState {
  const DeletionPreviewState();
}

final class DeletionPreviewLoading extends DeletionPreviewState {
  const DeletionPreviewLoading();
}

final class DeletionPreviewFailed extends DeletionPreviewState {
  const DeletionPreviewFailed(this.message);

  final String message;
}

final class DeletionPreviewLoaded extends DeletionPreviewState {
  const DeletionPreviewLoaded(this.preview);

  final DeletionPreview preview;
}
