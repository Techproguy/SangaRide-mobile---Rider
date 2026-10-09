import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/groups/group_bindings.dart';
import 'package:sanga_ride/controller/rider/groups/groups_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/who_for_endpoints.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/model/ride/ride_load_problem.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart' show ConnectionMonitor, JsonReader;

class RideForController extends GetxController {
  final _api = Get.find<ApiService>();

  final Rx<RideFor> _rideFor = Rx<RideFor>(const RideForMe());
  final Rx<PassengerFlowState> _passenger = Rx<PassengerFlowState>(const PassengerIdle());
  final Rx<RideForListState<FamilyMember>> _family = Rx<RideForListState<FamilyMember>>(const RideForListLoading());
  final Rx<RideForListState<BusinessProfile>> _business = Rx<RideForListState<BusinessProfile>>(
    const RideForListLoading(),
  );
  final Rxn<FamilyMember> _pickedMember = Rxn<FamilyMember>();
  final Rxn<BusinessProfile> _pickedProfile = Rxn<BusinessProfile>();

  RideFor get rideFor => _rideFor.value;

  PassengerFlowState get passengerState => _passenger.value;

  RideForListState<FamilyMember> get family => _family.value;

  RideForListState<BusinessProfile> get business => _business.value;

  FamilyMember? get pickedMember => _pickedMember.value;

  BusinessProfile? get pickedProfile => _pickedProfile.value;

  void select(RideFor value) => _rideFor.value = value;

  void reset() {
    _rideFor.value = const RideForMe();
    _passenger.value = const PassengerIdle();
    _pickedMember.value = null;
    _pickedProfile.value = null;
  }

  void pickMember(FamilyMember member) => _pickedMember.value = member;

  void pickProfile(BusinessProfile profile) => _pickedProfile.value = profile;

  void confirmMember() {
    final member = pickedMember;
    if (member != null) select(RideForFamily(member: member));
  }

  void confirmBusiness({required String purpose, String? note}) {
    final profile = pickedProfile;
    if (profile == null) return;
    select(RideForBusiness(profile: profile, purpose: purpose, note: note));
  }

  void confirmPassenger() {
    final state = passengerState;
    if (state is PassengerVerified) select(state.rideFor);
  }

  void clearPassengerFlow() => _passenger.value = const PassengerIdle();

  void clearPassengerSendFailure() {
    if (passengerState is PassengerSendFailed) _passenger.value = const PassengerIdle();
  }

  void clearPassengerCodeFailure() {
    final state = passengerState;
    if (state is! PassengerCodePending || state.failure == null || state.needsNewCode) return;
    _passenger.value = PassengerCodePending(info: state.info, verification: state.verification);
  }

  Future<({GroupDetail detail, GroupMember? me})?> _groupOf(GroupKind kind) async {
    final groups = Get.find<GroupsController>();
    await groups.open();
    if (groups.state is GroupsFailed) throw const FormatException('groups unavailable');
    final summary = groups.groupOf(kind);
    if (summary == null) return null;
    final group = GroupControllers.group(summary.id);
    await group.open();
    final detail = group.detail;
    if (detail == null) throw const FormatException('group unavailable');
    return (detail: detail, me: group.me);
  }

  bool _canBookFor(GroupMember member, GroupDetail detail, GroupMember? me) {
    if (member.isInvited) return false;
    if (detail.canManage) return true;
    if (member.id == me?.id) return me?.permissions.bookRides == true && me?.permissions.useGroupWallet == true;
    return me?.permissions.bookForOthers == true;
  }

  Future<void> loadFamily() async {
    if (family is! RideForListLoaded) _family.value = const RideForListLoading();
    try {
      final found = await _groupOf(GroupKind.family);
      final members = found == null
          ? <FamilyMember>[]
          : [
              for (final member in found.detail.members)
                if (_canBookFor(member, found.detail, found.me))
                  FamilyMember(
                    id: member.id,
                    groupId: found.detail.id,
                    groupName: found.detail.name,
                    name: member.name,
                    relationship: member.relation,
                    phone: member.phone,
                    isYou: member.id == found.me?.id,
                  ),
            ];
      _family.value = RideForListLoaded(members);
      _pickedMember.value = members.firstWhereOrNull((member) => member.id == pickedMember?.id);
      final current = rideFor;
      if (current is RideForFamily) _pickedMember.value ??= members.firstWhereOrNull((m) => m.id == current.member.id);
    } catch (e) {
      log('loadFamily failed: $e');
      if (family is! RideForListLoaded) _family.value = RideForListFailed(problem: RideLoadProblem.of(e));
    }
  }

  Future<void> loadBusinesses() async {
    if (business is! RideForListLoaded) _business.value = const RideForListLoading();
    try {
      final found = await _groupOf(GroupKind.business);
      final profiles = found == null
          ? <BusinessProfile>[]
          : [
              BusinessProfile(
                id: found.detail.id,
                companyName: found.detail.name,
                role: found.me?.relation ?? 'Team member',
                purposes: found.detail.recentPurposes,
              ),
            ];
      _business.value = RideForListLoaded(profiles);
      _pickedProfile.value = profiles.firstWhereOrNull((profile) => profile.id == pickedProfile?.id);
      final current = rideFor;
      if (current is RideForBusiness) {
        _pickedProfile.value ??= profiles.firstWhereOrNull((p) => p.id == current.profile.id);
      }
      if (profiles.length == 1) _pickedProfile.value ??= profiles.first;
    } catch (e) {
      log('loadBusinesses failed: $e');
      if (business is! RideForListLoaded) _business.value = RideForListFailed(problem: RideLoadProblem.of(e));
    }
  }

  IdempotencyKey? _codeKey;
  String? _codeSignature;

  bool get _isOffline => ConnectionMonitor.current?.isOnline == false;

  IdempotencyKey _keyFor(PassengerInfo info, {required bool isResend}) {
    final signature = '${info.toJson()}${isResend ? 'resend' : ''}';
    if (_codeKey == null || _codeSignature != signature) {
      _codeKey = IdempotencyKey.newFor(IdempotencyIntent.passengerCode);
      _codeSignature = signature;
    }
    return _codeKey!;
  }

  Future<bool> sendPassengerCode(PassengerInfo info) async {
    if (passengerState is PassengerSending) return false;
    if (_isOffline) {
      _passenger.value = const PassengerSendFailed(PassengerFailure.connection);
      return false;
    }
    _passenger.value = const PassengerSending();
    try {
      final verification = await _requestCode(info, isResend: false);
      _passenger.value = PassengerCodePending(info: info, verification: verification);
      _codeKey = null;
      return true;
    } catch (e) {
      log('sendPassengerCode failed: $e');
      _passenger.value = PassengerSendFailed(PassengerFailure.of(e));
      return false;
    }
  }

  Future<bool> resendPassengerCode() async {
    final state = passengerState;
    if (state is! PassengerCodePending || state.isResending) return false;
    if (_isOffline) {
      _passenger.value = PassengerCodePending(
        info: state.info,
        verification: state.verification,
        failure: PassengerFailure.connection,
      );
      return false;
    }
    _passenger.value = PassengerCodePending(info: state.info, verification: state.verification, isResending: true);
    try {
      final verification = await _requestCode(state.info, isResend: true);
      _passenger.value = PassengerCodePending(info: state.info, verification: verification);
      _codeKey = null;
      return true;
    } catch (e) {
      log('resendPassengerCode failed: $e');
      _passenger.value = PassengerCodePending(
        info: state.info,
        verification: state.verification,
        failure: PassengerFailure.of(e),
      );
      return false;
    }
  }

  Future<bool> verifyPassengerCode(String code) async {
    final state = passengerState;
    if (state is! PassengerCodePending || state.isResending) return false;
    if (_isOffline) {
      _passenger.value = PassengerCodePending(
        info: state.info,
        verification: state.verification,
        failure: PassengerFailure.connection,
      );
      return false;
    }
    _passenger.value = PassengerChecking(info: state.info, verification: state.verification);
    try {
      final response = await _api.post(
        WhoForEndpoints.passengerVerify,
        data: {'verificationId': state.verification.id, 'code': code},
        suppressErrorToast: true,
      );
      final verifiedAt = JsonReader.of((response.data as Map)['data']).timeOrNull('verifiedAt') ?? DateTime.now();
      _passenger.value = PassengerVerified(
        rideFor: RideForSomeone(passenger: state.info, verifiedAt: verifiedAt),
        verification: state.verification,
      );
      return true;
    } catch (e) {
      log('verifyPassengerCode failed: $e');
      _passenger.value = PassengerCodePending(
        info: state.info,
        verification: state.verification,
        failure: PassengerFailure.of(e),
        attemptsLeft: e is ApiException ? (e.data['attemptsLeft'] as num?)?.toInt() : null,
      );
      return false;
    }
  }

  Future<PassengerVerification> _requestCode(PassengerInfo info, {required bool isResend}) async {
    final response = await _api.post(
      WhoForEndpoints.passengerOtp,
      data: info.toJson(),
      key: _keyFor(info, isResend: isResend),
      suppressErrorToast: true,
    );
    return PassengerVerification.fromJson((response.data as Map)['data']);
  }
}
