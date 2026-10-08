import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/who_for_endpoints.dart';
import 'package:sanga_ride/model/models.dart';

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

  void confirmBusiness({required String purpose, String? costCentre, String? note}) {
    final profile = pickedProfile;
    if (profile == null) return;
    select(RideForBusiness(profile: profile, purpose: purpose, costCentre: costCentre, note: note));
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

  Future<void> loadFamily() async {
    if (family is! RideForListLoaded) _family.value = const RideForListLoading();
    try {
      final response = await _api.get(WhoForEndpoints.familyMembers, suppressErrorToast: true);
      final members = [
        for (final json in response.data['data'] as List) FamilyMember.fromJson(Map<String, dynamic>.from(json as Map)),
      ];
      _family.value = RideForListLoaded(members);
      _pickedMember.value = members.firstWhereOrNull((member) => member.id == pickedMember?.id);
      final current = rideFor;
      if (current is RideForFamily) _pickedMember.value ??= members.firstWhereOrNull((m) => m.id == current.member.id);
    } catch (e) {
      log('loadFamily failed: $e');
      if (family is! RideForListLoaded) _family.value = const RideForListFailed();
    }
  }

  Future<void> loadBusinesses() async {
    if (business is! RideForListLoaded) _business.value = const RideForListLoading();
    try {
      final response = await _api.get(WhoForEndpoints.businessProfiles, suppressErrorToast: true);
      final profiles = [
        for (final json in response.data['data'] as List)
          BusinessProfile.fromJson(Map<String, dynamic>.from(json as Map)),
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
      if (business is! RideForListLoaded) _business.value = const RideForListFailed();
    }
  }

  Future<bool> sendPassengerCode(PassengerInfo info) async {
    _passenger.value = const PassengerSending();
    try {
      final verification = await _requestCode(info);
      _passenger.value = PassengerCodePending(info: info, verification: verification);
      return true;
    } on ApiException catch (e) {
      _passenger.value = PassengerSendFailed(PassengerFailure.fromCode(e.code));
      return false;
    } catch (e) {
      log('sendPassengerCode failed: $e');
      _passenger.value = const PassengerSendFailed(PassengerFailure.connection);
      return false;
    }
  }

  Future<bool> resendPassengerCode() async {
    final state = passengerState;
    if (state is! PassengerCodePending || state.isResending) return false;
    _passenger.value = PassengerCodePending(info: state.info, verification: state.verification, isResending: true);
    try {
      final verification = await _requestCode(state.info);
      _passenger.value = PassengerCodePending(info: state.info, verification: verification);
      return true;
    } on ApiException catch (e) {
      _passenger.value = PassengerCodePending(
        info: state.info,
        verification: state.verification,
        failure: PassengerFailure.fromCode(e.code),
      );
      return false;
    } catch (e) {
      log('resendPassengerCode failed: $e');
      _passenger.value = PassengerCodePending(
        info: state.info,
        verification: state.verification,
        failure: PassengerFailure.connection,
      );
      return false;
    }
  }

  Future<bool> verifyPassengerCode(String code) async {
    final state = passengerState;
    if (state is! PassengerCodePending || state.isResending) return false;
    _passenger.value = PassengerChecking(info: state.info, verification: state.verification);
    try {
      final response = await _api.post(
        WhoForEndpoints.passengerVerify,
        data: {'verificationId': state.verification.id, 'code': code},
        suppressErrorToast: true,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final verifiedAt = DateTime.parse(data['verifiedAt'] as String);
      _passenger.value = PassengerVerified(
        rideFor: RideForSomeone(passenger: state.info, verifiedAt: verifiedAt),
        verification: state.verification,
      );
      return true;
    } on ApiException catch (e) {
      _passenger.value = PassengerCodePending(
        info: state.info,
        verification: state.verification,
        failure: PassengerFailure.fromCode(e.code),
        attemptsLeft: (e.data['attemptsLeft'] as num?)?.toInt(),
      );
      return false;
    } catch (e) {
      log('verifyPassengerCode failed: $e');
      _passenger.value = PassengerCodePending(
        info: state.info,
        verification: state.verification,
        failure: PassengerFailure.connection,
      );
      return false;
    }
  }

  Future<PassengerVerification> _requestCode(PassengerInfo info) async {
    final response = await _api.post(WhoForEndpoints.passengerOtp, data: info.toJson(), suppressErrorToast: true);
    return PassengerVerification.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
