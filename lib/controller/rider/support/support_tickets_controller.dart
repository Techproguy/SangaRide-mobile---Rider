import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_api.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/support_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

class SupportTicketsController extends GetxController {
  static const Duration _pollEvery = Duration(seconds: 3);

  final _api = Get.find<ApiService>();

  final Rx<TicketsState> _list = Rx<TicketsState>(const TicketsLoading());
  final Rx<TicketState> _detail = Rx<TicketState>(const TicketLoading());

  Timer? _poll;
  String? _openId;
  int _epoch = 0;

  TicketsState get list => _list.value;

  TicketState get detail => _detail.value;

  @override
  void onClose() {
    _poll?.cancel();
    super.onClose();
  }

  Future<void> loadList() async {
    try {
      final page = await _fetchList(1);
      _list.value = TicketsLoaded(page.items, page: page.page, hasMore: page.hasMore);
    } catch (error) {
      log('tickets failed: $error');
      if (_list.value is! TicketsLoaded) _list.value = const TicketsFailed();
    }
  }

  Future<void> retryList() async {
    _list.value = const TicketsLoading();
    await loadList();
  }

  Future<void> loadMore() async {
    final current = _list.value;
    if (current is! TicketsLoaded || !current.hasMore || current.isLoadingMore) return;
    _list.value = current.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await _fetchList(current.page + 1);
      _list.value = TicketsLoaded([...current.items, ...page.items], page: page.page, hasMore: page.hasMore);
    } catch (error) {
      log('tickets page failed: $error');
      _list.value = current.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  Future<void> open(String id, {SupportTicket? known}) async {
    _poll?.cancel();
    _openId = id;
    final epoch = ++_epoch;
    _detail.value = known == null ? const TicketLoading() : TicketLoaded(known);
    _schedulePoll(known);
    await _load(id, epoch);
  }

  Future<void> reload() async {
    final id = _openId;
    if (id == null) return;
    _detail.value = const TicketLoading();
    await _load(id, ++_epoch);
  }

  void close() {
    _poll?.cancel();
    _openId = null;
  }

  Future<bool> choose(String optionId) async {
    final current = _detail.value;
    final id = _openId;
    if (current is! TicketLoaded || current.isChoosing || id == null) return false;
    _poll?.cancel();
    _detail.value = TicketLoaded(current.ticket, isChoosing: true);
    try {
      final response = await _api.post(
        SupportEndpoints.of(SupportEndpoints.ticketResolution, id),
        data: {'option': optionId},
        options: quietOptions,
      );
      final ticket = SupportTicket.fromJson(dataOf(response));
      _detail.value = TicketLoaded(ticket);
      _schedulePoll(ticket);
      unawaited(loadList());
      return true;
    } catch (error) {
      log('resolution failed: $error');
      _detail.value = TicketLoaded(current.ticket, problem: _problemOf(error));
      return false;
    }
  }

  Future<void> _load(String id, int epoch) async {
    try {
      final response = await _api.get(SupportEndpoints.of(SupportEndpoints.ticket, id), options: quietOptions);
      if (epoch != _epoch) return;
      final ticket = SupportTicket.fromJson(dataOf(response));
      final previous = _detail.value;
      if (previous is TicketLoaded && previous.isChoosing) return;
      _detail.value = TicketLoaded(ticket);
      _schedulePoll(ticket);
    } catch (error) {
      log('ticket failed: $error');
      if (epoch != _epoch) return;
      final current = _detail.value;
      if (current is TicketLoaded) return _schedulePoll(current.ticket);
      _detail.value = TicketFailed(_problemOf(error));
    }
  }

  void _schedulePoll(SupportTicket? ticket) {
    _poll?.cancel();
    final id = _openId;
    if (id == null || (ticket != null && !ticket.status.isWaiting)) return;
    final epoch = _epoch;
    _poll = Timer(_pollEvery, () => _load(id, epoch));
  }

  Future<TicketsPage> _fetchList(int page) async {
    final response = await _api.get(SupportEndpoints.tickets, queryParameters: {'page': page}, options: quietOptions);
    return TicketsPage.fromJson(dataOf(response));
  }

  SupportProblem _problemOf(Object error) =>
      error is ApiException ? SupportProblem.fromCode(error.code) : SupportProblem.connection;
}
