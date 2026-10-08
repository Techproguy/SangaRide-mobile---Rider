enum DeliveryIssueReason {
  driverNotMoving('driver_not_moving', 'Driver not moving', 'Driver has stopped for too long'),
  cannotReachDriver('cannot_reach_driver', 'Cannot reach driver', 'Driver is not responding'),
  wrongLocation('wrong_location', 'Wrong location', 'Driver is at a different location'),
  extraPayment('extra_payment', 'Driver asked for extra payment', 'Additional payment query'),
  unableToComplete('unable_to_complete', 'Unable to complete delivery', 'Driver cannot deliver the package'),
  safety('safety', 'Safety concern', 'I feel something is wrong'),
  other('other', 'Other', 'Something not listed above');

  const DeliveryIssueReason(this.code, this.label, this.hint);

  final String code;
  final String label;
  final String hint;

  bool get needsNote => this == other;

  bool get pointsToSafety => this == safety;

  static DeliveryIssueReason? fromCode(String? code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    return null;
  }
}

abstract final class DeliveryIssueRules {
  static const int maxNoteLength = 300;
  static const int minOtherNoteLength = 10;

  static bool isReady(DeliveryIssueReason? reason, String note) {
    if (reason == null) return false;
    return !reason.needsNote || note.trim().length >= minOtherNoteLength;
  }
}

enum DeliveryIssueStatus {
  reported('reported'),
  investigating('investigating'),
  actionNeeded('action_needed'),
  resolved('resolved');

  const DeliveryIssueStatus(this.code);

  final String code;

  bool get isOpen => this != resolved;

  static DeliveryIssueStatus fromCode(String code) => values.firstWhere(
    (status) => status.code == code,
    orElse: () => throw FormatException('Unknown issue status: $code'),
  );
}

enum DeliveryIssueEventType {
  reported('reported', 'Issue reported'),
  investigating('investigating', 'Looking into it'),
  actionTaken('action_taken', 'Action taken'),
  resolved('resolved', 'Resolved');

  const DeliveryIssueEventType(this.code, this.title);

  final String code;
  final String title;

  static DeliveryIssueEventType? fromCode(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

class DeliveryIssueEvent {
  const DeliveryIssueEvent({required this.type, required this.at, required this.detail});

  static DeliveryIssueEvent? tryParse(Map<String, dynamic> json) {
    final type = DeliveryIssueEventType.fromCode(json['type'] as String?);
    if (type == null) return null;
    final at = json['at'] as String?;
    return DeliveryIssueEvent(
      type: type,
      at: at == null ? null : DateTime.parse(at).toLocal(),
      detail: json['detail'] as String?,
    );
  }

  final DeliveryIssueEventType type;
  final DateTime? at;
  final String? detail;
}

class DeliveryResolutionOption {
  const DeliveryResolutionOption({required this.id, required this.label, required this.blurb});

  factory DeliveryResolutionOption.fromJson(Map<String, dynamic> json) => DeliveryResolutionOption(
    id: json['id'] as String,
    label: json['label'] as String,
    blurb: json['blurb'] as String? ?? '',
  );

  final String id;
  final String label;
  final String blurb;
}

class DeliveryIssue {
  const DeliveryIssue({
    required this.id,
    required this.reference,
    required this.status,
    required this.events,
    required this.options,
  });

  factory DeliveryIssue.fromJson(Map<String, dynamic> json) {
    final options = json['resolutionOptions'] as List?;
    return DeliveryIssue(
      id: json['id'] as String,
      reference: json['reference'] as String,
      status: DeliveryIssueStatus.fromCode(json['status'] as String),
      events: [
        for (final event in json['events'] as List? ?? const [])
          ?DeliveryIssueEvent.tryParse(Map<String, dynamic>.from(event as Map)),
      ],
      options: [
        for (final option in options ?? const [])
          DeliveryResolutionOption.fromJson(Map<String, dynamic>.from(option as Map)),
      ],
    );
  }

  final String id;
  final String reference;
  final DeliveryIssueStatus status;
  final List<DeliveryIssueEvent> events;
  final List<DeliveryResolutionOption> options;

  DeliveryIssueEvent? eventOf(DeliveryIssueEventType type) {
    for (final event in events) {
      if (event.type == type) return event;
    }
    return null;
  }
}

enum DeliveryIssueProblem {
  tripEnded(
    'trip_ended',
    'This delivery has ended',
    'You can’t report an issue on a delivery that’s already finished.',
    canRetry: false,
  ),
  optionUnavailable(
    'option_unavailable',
    'That option isn’t available anymore',
    'Pick one of the options on screen to carry on.',
    canRetry: true,
  ),
  connection(
    'connection',
    'We couldn’t reach the server',
    'Check your connection and give it another go.',
    canRetry: true,
  );

  const DeliveryIssueProblem(this.code, this.title, this.message, {required this.canRetry});

  final String code;
  final String title;
  final String message;
  final bool canRetry;

  static DeliveryIssueProblem fromCode(String? code) =>
      values.firstWhere((problem) => problem.code == code, orElse: () => connection);
}

sealed class DeliveryIssueState {
  const DeliveryIssueState();
}

final class IssueIdle extends DeliveryIssueState {
  const IssueIdle();
}

final class IssueSubmitting extends DeliveryIssueState {
  const IssueSubmitting(this.reason, this.note);

  final DeliveryIssueReason reason;
  final String note;
}

final class IssueSubmitFailed extends DeliveryIssueState {
  const IssueSubmitFailed(this.problem, this.reason, this.note);

  final DeliveryIssueProblem problem;
  final DeliveryIssueReason reason;
  final String note;
}

final class IssueLoading extends DeliveryIssueState {
  const IssueLoading();
}

sealed class IssueLoaded extends DeliveryIssueState {
  const IssueLoaded(this.issue);

  final DeliveryIssue issue;
}

final class IssueInProgress extends IssueLoaded {
  const IssueInProgress(super.issue, {this.isStale = false});

  final bool isStale;
}

final class IssueActionNeeded extends IssueLoaded {
  const IssueActionNeeded(super.issue, {required this.selectedId});

  final String? selectedId;

  IssueActionNeeded withSelected(String id) => IssueActionNeeded(issue, selectedId: id);
}

final class IssueResolving extends IssueLoaded {
  const IssueResolving(super.issue, {required this.optionId});

  final String optionId;
}

final class IssueResolutionFailed extends IssueLoaded {
  const IssueResolutionFailed(super.issue, {required this.optionId, required this.problem});

  final String optionId;
  final DeliveryIssueProblem problem;
}

final class IssueResolved extends IssueLoaded {
  const IssueResolved(super.issue);
}

final class IssueUnavailable extends DeliveryIssueState {
  const IssueUnavailable(this.problem);

  final DeliveryIssueProblem problem;
}
