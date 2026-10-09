import 'dart:async';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/support_endpoints.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class SupportTicketsController extends GetxController {
  static const Duration _pollEvery = Duration(seconds: 20);

  final _api = Get.find<ApiService>();

  final Rx<TicketsState> _list = Rx<TicketsState>(const TicketsLoading());
  final Rx<TicketState> _detail = Rx<TicketState>(const TicketLoading());

  LivePoller? _poller;
  Mutation<SupportTicket>? _choice;
  String? _openId;
  int _listEpoch = 0;
  int _epoch = 0;

  TicketsState get list => _list.value;

  TicketState get detail => _detail.value;

  @override
  void onClose() {
    _stopPolling();
    _choice?.dispose();
    super.onClose();
  }

  Future<void> loadList() async {
    final epoch = ++_listEpoch;
    try {
      final page = await _fetchList(1);
      if (epoch != _listEpoch) return;
      _list.value = TicketsLoaded(page.items, page: page.page, hasMore: page.hasMore);
    } on Object catch (error) {
      if (epoch != _listEpoch) return;
      final current = _list.value;
      _list.value = current is TicketsLoaded
          ? current.copyWith(isStale: true)
          : TicketsFailed(SupportProblem.of(error));
    }
  }

  Future<void> retryList() async {
    _list.value = const TicketsLoading();
    await loadList();
  }

  Future<void> loadMore() async {
    final current = _list.value;
    if (current is! TicketsLoaded || !current.hasMore || current.isLoadingMore) return;
    final epoch = ++_listEpoch;
    _list.value = current.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await _fetchList(current.page + 1);
      if (epoch != _listEpoch) return;
      _list.value = TicketsLoaded([...current.items, ...page.items], page: page.page, hasMore: page.hasMore);
    } on Object {
      if (epoch == _listEpoch) _list.value = current.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  Future<void> open(String id, {SupportTicket? known}) async {
    _stopPolling();
    _openId = id;
    final epoch = ++_epoch;
    _detail.value = known == null ? const TicketLoading() : TicketLoaded(known);
    try {
      await _load(id, epoch);
    } on Object catch (error) {
      if (epoch == _epoch && _detail.value is! TicketLoaded) _detail.value = TicketFailed(SupportProblem.of(error));
    }
  }

  Future<void> reload() async {
    final id = _openId;
    if (id == null) return;
    _detail.value = const TicketLoading();
    final epoch = ++_epoch;
    try {
      await _load(id, epoch);
    } on Object catch (error) {
      if (epoch == _epoch) _detail.value = TicketFailed(SupportProblem.of(error));
    }
  }

  void close() {
    _stopPolling();
    _openId = null;
    _epoch++;
  }

  Future<bool> choose(String optionId) async {
    final current = _detail.value;
    final id = _openId;
    if (current is! TicketLoaded || current.isChoosing || id == null) return false;
    _stopPolling();
    _detail.value = TicketLoaded(current.ticket, isChoosing: true);
    _choice?.dispose();
    final mutation = _choice = Mutation<SupportTicket>(
      intent: 'ticket-resolution',
      run: (key) async {
        final response = await _api.post(
          SupportEndpoints.of(SupportEndpoints.ticketResolution, id),
          data: {'option': optionId},
          key: key,
          options: quietOptions,
        );
        return SupportTicket.fromJson(dataOf(response));
      },
      reconcile: () async {
        final response = await _api.get(SupportEndpoints.of(SupportEndpoints.ticket, id), options: quietOptions);
        final ticket = SupportTicket.fromJson(dataOf(response));
        return ticket.status == TicketStatus.actionNeeded
            ? const ReconciledNotDone<SupportTicket>()
            : ReconciledDone(ticket);
      },
    );
    switch (await mutation.start()) {
      case MutationDone<SupportTicket>(:final value):
        _detail.value = TicketLoaded(value);
        _syncPoller(value, _epoch);
        unawaited(loadList());
        return true;
      case MutationRejected<SupportTicket>(:final error) || MutationFailed<SupportTicket>(:final error):
        _detail.value = TicketLoaded(current.ticket, problem: SupportProblem.of(error));
      case MutationUnknown<SupportTicket>():
        _detail.value = TicketLoaded(current.ticket, problem: SupportProblem.unconfirmed);
      case MutationIdle<SupportTicket>() || MutationRunning<SupportTicket>() || MutationChecking<SupportTicket>():
        _detail.value = TicketLoaded(current.ticket);
    }
    _syncPoller(current.ticket, _epoch);
    return false;
  }

  Future<void> _load(String id, int epoch) async {
    final response = await _api.get(SupportEndpoints.of(SupportEndpoints.ticket, id), options: quietOptions);
    if (epoch != _epoch) return;
    final ticket = SupportTicket.fromJson(dataOf(response));
    final previous = _detail.value;
    if (previous is TicketLoaded && previous.isChoosing) return;
    _detail.value = TicketLoaded(ticket);
    _syncPoller(ticket, epoch);
  }

  void _syncPoller(SupportTicket? ticket, int epoch) {
    final id = _openId;
    final shouldPoll = id != null && (ticket == null || ticket.status.isWaiting);
    if (!shouldPoll) return _stopPolling();
    if (_poller != null) return;
    final poller = LivePoller(fetch: () => _load(id, epoch), interval: _pollEvery);
    _poller = poller;
    poller.start();
  }

  void _stopPolling() {
    final poller = _poller;
    _poller = null;
    if (poller != null) Future<void>.microtask(poller.dispose);
  }

  Future<TicketsPage> _fetchList(int page) async {
    final response = await _api.get(SupportEndpoints.tickets, queryParameters: {'page': page}, options: quietOptions);
    return TicketsPage.fromJson(dataOf(response));
  }
}
