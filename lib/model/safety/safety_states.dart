import 'package:sanga_ride/model/safety/safety_centre.dart';
import 'package:sanga_ride/model/safety/safety_problem.dart';
import 'package:sanga_ride/model/safety/safety_report.dart';
import 'package:sanga_ride/model/safety/sos.dart';

sealed class SafetyCentreState {
  const SafetyCentreState();
}

final class SafetyCentreLoading extends SafetyCentreState {
  const SafetyCentreLoading();
}

final class SafetyCentreLoaded extends SafetyCentreState {
  const SafetyCentreLoaded(this.centre);

  final SafetyCentre centre;
}

final class SafetyCentreFailed extends SafetyCentreState {
  const SafetyCentreFailed(this.problem);

  final SafetyProblem problem;
}

sealed class SosState {
  const SosState();
}

final class SosIdle extends SosState {
  const SosIdle();
}

final class SosActivating extends SosState {
  const SosActivating(this.startedAt);

  final DateTime startedAt;
}

final class SosSending extends SosState {
  const SosSending();
}

final class SosActive extends SosState {
  const SosActive(this.sos);

  final Sos sos;
}

final class SosEnding extends SosState {
  const SosEnding(this.sos);

  final Sos sos;
}

final class SosFailed extends SosState {
  const SosFailed(this.problem);

  final SafetyProblem problem;
}

sealed class ContactsState {
  const ContactsState();
}

final class ContactsIdle extends ContactsState {
  const ContactsIdle();
}

final class ContactsAdding extends ContactsState {
  const ContactsAdding();
}

final class ContactsRemoving extends ContactsState {
  const ContactsRemoving(this.id);

  final String id;
}

final class ContactsFailed extends ContactsState {
  const ContactsFailed(this.problem);

  final SafetyProblem problem;
}

sealed class ReportState {
  const ReportState();
}

final class ReportIdle extends ReportState {
  const ReportIdle();
}

final class ReportSubmitting extends ReportState {
  const ReportSubmitting();
}

final class ReportFailed extends ReportState {
  const ReportFailed(this.problem);

  final SafetyProblem problem;
}

final class ReportSent extends ReportState {
  const ReportSent(this.receipt);

  final SafetyReportReceipt receipt;
}
