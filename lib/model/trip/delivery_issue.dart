import 'package:sanga_ride/model/support/support_ticket.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class DeliveryIssueRules {
  static const String safetyCategoryId = 'safety_concern';
  // TODO(#270): drop the note limit and the safety category id when GET /issues/categories returns maxDescription and a pointsToSafety flag
  static const int maxNoteLength = 300;

  static bool pointsToSafety(IssueType reason) => reason.id == safetyCategoryId;

  static bool isReady(IssueType? reason, String note) {
    if (reason == null) return false;
    return !reason.requiresDescription || note.trim().isNotEmpty;
  }
}

sealed class IssueReasonsState {
  const IssueReasonsState();
}

final class IssueReasonsLoading extends IssueReasonsState {
  const IssueReasonsLoading();
}

final class IssueReasonsFailed extends IssueReasonsState {
  const IssueReasonsFailed(this.problem);

  final DeliveryIssueProblem problem;
}

final class IssueReasonsLoaded extends IssueReasonsState {
  const IssueReasonsLoaded(this.reasons);

  final List<IssueType> reasons;
}

enum DeliveryIssueStatus {
  reported('reported'),
  investigating('investigating'),
  actionNeeded('action_needed'),
  resolved('resolved'),
  unknown('unknown');

  const DeliveryIssueStatus(this.code);

  final String code;

  bool get isOpen => this != resolved;

  static DeliveryIssueStatus fromCode(String? code) => enumByCode(values, code, (status) => status.code, unknown);
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
    final reader = JsonReader.of(json);
    final type = DeliveryIssueEventType.fromCode(reader.strOrNull('type'));
    if (type == null) return null;
    return DeliveryIssueEvent(type: type, at: reader.timeOrNull('at')?.toLocal(), detail: reader.strOrNull('detail'));
  }

  final DeliveryIssueEventType type;
  final DateTime? at;
  final String? detail;
}

class DeliveryResolutionOption {
  const DeliveryResolutionOption({required this.id, required this.label, required this.blurb});

  factory DeliveryResolutionOption.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return DeliveryResolutionOption(id: reader.str('id'), label: reader.str('label'), blurb: reader.strOr('blurb', ''));
  }

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
    final reader = JsonReader.of(json);
    return DeliveryIssue(
      id: reader.str('id'),
      reference: reader.strOr('reference', ''),
      status: DeliveryIssueStatus.fromCode(reader.strOrNull('status')),
      events: reader.listOf('events', (event) => DeliveryIssueEvent.tryParse(event.raw)!),
      options: reader.listOf('resolutionOptions', (option) => DeliveryResolutionOption.fromJson(option.raw)),
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
  connection('connection', SangaCommonCopy.unreachableTitle, SangaCommonCopy.connectionAnotherGo, canRetry: true),
  unknown('unknown', SangaCommonCopy.somethingWentWrong, SangaCommonCopy.serverTrouble, canRetry: true);

  const DeliveryIssueProblem(this.code, this.title, this.message, {required this.canRetry});

  final String code;
  final String title;
  final String message;
  final bool canRetry;

  static DeliveryIssueProblem fromCode(String? code) => enumByCode(values, code, (problem) => problem.code, unknown);

  static DeliveryIssueProblem of(Object error) {
    if (error is ApiException && error.kind == ApiFailureKind.rejected) return fromCode(error.code);
    return switch (ProblemKind.of(error)) {
      ProblemOffline() => connection,
      _ => unknown,
    };
  }
}

sealed class DeliveryIssueState {
  const DeliveryIssueState();
}

final class IssueIdle extends DeliveryIssueState {
  const IssueIdle();
}

final class IssueSubmitting extends DeliveryIssueState {
  const IssueSubmitting(this.reason, this.note);

  final IssueType reason;
  final String note;
}

final class IssueSubmitFailed extends DeliveryIssueState {
  const IssueSubmitFailed(this.problem, this.reason, this.note);

  final DeliveryIssueProblem problem;
  final IssueType reason;
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
