import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart' show Options;
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/group_endpoints.dart';
import 'package:sanga_ride/model/groups/group_models.dart';

class GroupsController extends GetxController {
  static final Options _noAutoRetry = Options(extra: {'retries': 3});

  final _api = Get.find<ApiService>();

  final Rx<GroupsState> _state = Rx<GroupsState>(const GroupsLoading());
  final RxBool _isBusy = false.obs;
  int _epoch = 0;

  Rx<GroupsState> get stateRx => _state;

  GroupsState get state => _state.value;

  bool get isBusy => _isBusy.value;

  GroupsOverview? get overview => switch (state) {
    GroupsLoaded(:final overview) => overview,
    _ => null,
  };

  GroupSummary? groupOf(GroupKind kind) => overview?.groupOf(kind);

  @override
  void onClose() {
    _epoch++;
    super.onClose();
  }

  Future<void> open() async {
    if (state is GroupsLoaded) return reloadQuietly();
    await reload();
  }

  Future<void> reload() async {
    _state.value = const GroupsLoading();
    await reloadQuietly();
  }

  Future<void> reloadQuietly() async {
    final epoch = ++_epoch;
    try {
      final response = await _api.get(GroupEndpoints.groups, suppressErrorToast: true);
      if (epoch != _epoch) return;
      _state.value = GroupsLoaded(GroupsOverview.fromJson(_dataOf(response.data)));
    } catch (e) {
      log('groups load failed: ${_describe(e)}');
      if (epoch == _epoch && state is! GroupsLoaded) _state.value = const GroupsFailed();
    }
  }

  Future<GroupOutcome> create({
    required GroupKind kind,
    required String name,
    required String role,
    GroupCompany? company,
  }) => _submit(GroupEndpoints.groups, {
    'kind': kind.code,
    'name': name.trim(),
    'role': role,
    'company': company?.toJson(),
  });

  Future<GroupOutcome> join(String code) => _submit(GroupEndpoints.join, {'code': code});

  Future<GroupOutcome> accept(GroupInvite invite) => _submit(GroupEndpoints.inviteAcceptOf(invite.id), null);

  Future<GroupOutcome> decline(GroupInvite invite) => _submit(GroupEndpoints.inviteDeclineOf(invite.id), null);

  Future<GroupOutcome> _submit(String endpoint, Map<String, dynamic>? body) async {
    if (isBusy) return const GroupRejected(GroupFailure.connection);
    _isBusy.value = true;
    try {
      final response = await _api.post(endpoint, data: body, options: _noAutoRetry, suppressErrorToast: true);
      unawaited(reloadQuietly());
      final data = (response.data as Map)['data'];
      return GroupDone(data is Map ? data['id'] as String? : null);
    } catch (e) {
      log('groups request failed: ${_describe(e)}');
      return GroupRejected(GroupFailure.fromCode(e is ApiException ? e.code : null));
    } finally {
      _isBusy.value = false;
    }
  }

  String _describe(Object error) => error is ApiException ? '${error.code}' : '${error.runtimeType}';

  Map<String, dynamic> _dataOf(dynamic body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
}
