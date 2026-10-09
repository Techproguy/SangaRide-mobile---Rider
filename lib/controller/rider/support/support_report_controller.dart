import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/history_endpoints.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
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
  final Epoch _epoch = Epoch();

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
    final epoch = _epoch.next();
    _state.value = const SupportReportLoading();
    try {
      final response = await _api.get(
        SupportEndpoints.issueTypes,
        queryParameters: {'context': context.code},
        suppressErrorToast: true,
      );
      final rides = _rides ??= await _recentRides();
      if (!_epoch.isCurrent(epoch)) return;
      _state.value = SupportReportDraft(
        types: JsonReader(response.dataMapOrEmpty).listOf('types', IssueType.fromReader),
        recentRides: _ridesFor(context, rides),
        tripId: tripId,
      );
    } on Object catch (error) {
      if (_epoch.isCurrent(epoch)) _state.value = SupportReportFailed(SupportProblem.of(error));
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
      intent: IdempotencyIntent.supportTicket,
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
          suppressErrorToast: true,
        );
        return SupportTicket.fromJson(response.dataMapOrEmpty);
      },
      reconcile: () => _reconcileTicket(_submission?.key.value),
    );
  }

  Future<Reconciled<SupportTicket>> _reconcileTicket(String? key) async {
    if (key == null) return const ReconciledPending<SupportTicket>();
    final response = await _api.get(
      SupportEndpoints.tickets,
      queryParameters: {'idempotencyKey': key},
      suppressErrorToast: true,
    );
    final found = TicketsPage.fromJson(response.dataMapOrEmpty).items.firstOrNull;
    if (found == null) return const ReconciledNotDone<SupportTicket>();
    final detail = await _api.get(SupportEndpoints.of(SupportEndpoints.ticket, found.id), suppressErrorToast: true);
    return ReconciledDone(SupportTicket.fromJson(detail.dataMapOrEmpty));
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
        suppressErrorToast: true,
      );
      return HistoryPage.fromJson(response.dataMapOrEmpty).items;
    } on Object {
      return const [];
    }
  }
}
