import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/history_endpoints.dart';
import 'package:sanga_ride/core/api/support_endpoints.dart';
import 'package:sanga_ride/model/history/history_item.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class SupportReportController extends GetxController {
  static const int recentRidesLimit = 8;

  final _api = Get.find<ApiService>();

  final Rx<SupportReportState> _state = Rx<SupportReportState>(const SupportReportLoading());

  IssueContext _context = IssueContext.trip;
  List<HistoryItem>? _rides;
  Mutation<SupportTicket>? _submission;
  String? _submissionSignature;
  int _epoch = 0;

  SupportReportState get state => _state.value;

  IssueContext get context => _context;

  @override
  void onClose() {
    _submission?.dispose();
    super.onClose();
  }

  Future<void> open({required IssueContext context, String? tripId, bool refreshRides = true}) async {
    _context = context;
    if (refreshRides) _rides = null;
    final epoch = ++_epoch;
    _state.value = const SupportReportLoading();
    try {
      final response = await _api.get(
        SupportEndpoints.issueTypes,
        queryParameters: {'context': context.code},
        options: quietOptions,
      );
      final rides = _rides ??= await _recentRides();
      if (epoch != _epoch) return;
      _state.value = SupportReportDraft(
        types: JsonReader(dataOf(response)).listOf('types', IssueType.fromReader),
        recentRides: _ridesFor(context, rides),
        tripId: tripId,
      );
    } on Object catch (error) {
      if (epoch == _epoch) _state.value = SupportReportFailed(SupportProblem.of(error));
    }
  }

  Future<void> reload() => open(context: _context, tripId: _draft?.tripId, refreshRides: false);

  Future<void> changeContext(IssueContext context) {
    final draft = _draft;
    if (draft != null && (context == _context || draft.isSubmitting)) return Future.value();
    return open(context: context, refreshRides: false);
  }

  void selectType(String id) {
    final draft = _draft;
    if (draft == null || draft.isSubmitting) return;
    _state.value = draft.copyWith(typeId: id, clearProblem: true);
  }

  void selectTrip(String? id) {
    final draft = _draft;
    if (draft == null || draft.isSubmitting) return;
    _state.value = id == null ? draft.copyWith(clearTrip: true) : draft.copyWith(tripId: id);
  }

  Future<SupportTicket?> submit({String? note}) async {
    final draft = _draft;
    final typeId = draft?.typeId;
    if (draft == null || typeId == null || draft.isSubmitting) return null;
    final trimmed = note?.trim() ?? '';
    final mutation = _submissionFor(draft, typeId, trimmed);
    _state.value = draft.copyWith(isSubmitting: true, clearProblem: true);
    final result = await (mutation.state.value is MutationUnknown<SupportTicket>
        ? mutation.recheck()
        : mutation.start());
    final current = _draft ?? draft;
    switch (result) {
      case MutationDone<SupportTicket>(:final value):
        _state.value = current.copyWith(isSubmitting: false);
        _submission = null;
        return value;
      case MutationRejected<SupportTicket>(:final error):
        mutation.reset();
        _state.value = current.copyWith(isSubmitting: false, problem: SupportProblem.of(error));
      case MutationFailed<SupportTicket>(:final error):
        mutation.reset(keepKey: true);
        _state.value = current.copyWith(isSubmitting: false, problem: SupportProblem.of(error));
      case MutationUnknown<SupportTicket>():
        _state.value = current.copyWith(isSubmitting: false, problem: SupportProblem.unconfirmed);
      case MutationIdle<SupportTicket>() || MutationRunning<SupportTicket>() || MutationChecking<SupportTicket>():
        _state.value = current.copyWith(isSubmitting: false);
    }
    return null;
  }

  Mutation<SupportTicket> _submissionFor(SupportReportDraft draft, String typeId, String note) {
    final signature = '${_context.code}|$typeId|${draft.tripId ?? ''}|$note';
    final existing = _submission;
    if (existing != null && _submissionSignature == signature) return existing;
    existing?.dispose();
    _submissionSignature = signature;
    final tripId = draft.tripId;
    final context = _context;
    return _submission = Mutation<SupportTicket>(
      intent: 'support-ticket',
      run: (key) async {
        final response = await _api.post(
          SupportEndpoints.tickets,
          data: {
            'type': typeId,
            'context': context.code,
            'tripId': tripId,
            'note': note.isEmpty ? null : note,
            'attachmentIds': const <String>[],
          },
          key: key,
          options: quietOptions,
        );
        return SupportTicket.fromJson(dataOf(response));
      },
      reconcile: () => _reconcileTicket(_submission?.key.value),
    );
  }

  Future<Reconciled<SupportTicket>> _reconcileTicket(String? key) async {
    if (key == null) return const ReconciledPending<SupportTicket>();
    final response = await _api.get(
      SupportEndpoints.tickets,
      queryParameters: {'idempotencyKey': key},
      options: quietOptions,
    );
    final found = TicketsPage.fromJson(dataOf(response)).items.firstOrNull;
    if (found == null) return const ReconciledNotDone<SupportTicket>();
    final detail = await _api.get(SupportEndpoints.of(SupportEndpoints.ticket, found.id), options: quietOptions);
    return ReconciledDone(SupportTicket.fromJson(dataOf(detail)));
  }

  SupportReportDraft? get _draft => switch (_state.value) {
    final SupportReportDraft draft => draft,
    _ => null,
  };

  List<HistoryItem> _ridesFor(IssueContext context, List<HistoryItem> rides) => switch (context) {
    IssueContext.trip => [
      for (final ride in rides)
        if (!ride.kind.isDelivery) ride,
    ],
    IssueContext.delivery => [
      for (final ride in rides)
        if (ride.kind.isDelivery) ride,
    ],
    IssueContext.account || IssueContext.payment => rides,
  };

  Future<List<HistoryItem>> _recentRides() async {
    try {
      final response = await _api.get(
        HistoryEndpoints.rides,
        queryParameters: {'status': HistoryStatus.completed.code, 'page': 1, 'pageSize': recentRidesLimit},
        options: quietOptions,
      );
      return HistoryPage.fromJson(dataOf(response)).items;
    } on Object {
      return const [];
    }
  }
}
