import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/model/support/support_problem.dart';
import 'package:sanga_ride/model/support/support_ticket.dart';

sealed class SupportReportState {
  const SupportReportState();
}

final class SupportReportLoading extends SupportReportState {
  const SupportReportLoading();
}

final class SupportReportFailed extends SupportReportState {
  const SupportReportFailed(this.problem);

  final SupportProblem problem;
}

final class SupportReportDraft extends SupportReportState {
  const SupportReportDraft({
    required this.types,
    required this.recentRides,
    this.typeId,
    this.tripId,
    this.isSubmitting = false,
    this.problem,
  });

  final List<IssueType> types;
  final List<HistoryItem> recentRides;
  final String? typeId;
  final String? tripId;
  final bool isSubmitting;
  final SupportProblem? problem;

  IssueType? get type => types.where((type) => type.id == typeId).firstOrNull;

  HistoryItem? get trip => recentRides.where((ride) => ride.id == tripId).firstOrNull;

  SupportReportDraft copyWith({
    String? typeId,
    String? tripId,
    bool clearTrip = false,
    bool? isSubmitting,
    SupportProblem? problem,
    bool clearProblem = false,
  }) => SupportReportDraft(
    types: types,
    recentRides: recentRides,
    typeId: typeId ?? this.typeId,
    tripId: clearTrip ? null : tripId ?? this.tripId,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    problem: clearProblem ? null : problem ?? this.problem,
  );
}
