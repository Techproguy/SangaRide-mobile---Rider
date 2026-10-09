import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/safety_centre_controller.dart';
import 'package:sanga_ride/controller/rider/trip/live_problem.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/idempotency_intents.dart';
import 'package:sanga_ride/core/api/safety_endpoints.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ContactsController extends GetxController {
  final _api = Get.find<ApiService>();
  final _centre = Get.find<SafetyCentreController>();

  final Rx<ContactsState> _state = Rx<ContactsState>(const ContactsIdle());
  Mutation<EmergencyContact>? _addMutation;
  String? _addSignature;

  Rx<ContactsState> get stateRx => _state;

  ContactsState get state => _state.value;

  bool get isBusy => state is ContactsAdding || state is ContactsRemoving;

  @override
  void onClose() {
    _addMutation?.dispose();
    super.onClose();
  }

  void reset() => _state.value = const ContactsIdle();

  void clearProblem() {
    if (state is ContactsFailed) _state.value = const ContactsIdle();
  }

  Future<void> reloadContacts() async {
    try {
      final response = await _api.get(SafetyEndpoints.contacts, suppressErrorToast: true);
      _centre.applyContacts(_contactsOf(response.dataMapOrEmpty));
    } catch (e) {
      log('contacts refresh failed: $e');
    }
  }

  Future<bool> add({required String name, required String phone}) async {
    final current = _centre.centre;
    if (current == null || isBusy) return false;
    if (LiveProblem.isOffline) {
      _state.value = const ContactsFailed(SafetyProblem.connection);
      return false;
    }
    _state.value = const ContactsAdding();
    final mutation = _addMutationFor(name, phone);
    final result = await mutation.start();
    switch (result) {
      case MutationDone<EmergencyContact>(:final value):
        _releaseAdd();
        final latest = (_centre.centre ?? current).contacts;
        if (!latest.any((contact) => contact.id == value.id)) _centre.applyContacts([...latest, value]);
        _state.value = const ContactsIdle();
        return true;
      case MutationRejected<EmergencyContact>(:final error):
        _releaseAdd();
        _state.value = ContactsFailed(SafetyProblem.of(error));
      case MutationFailed<EmergencyContact>(:final error):
        _state.value = ContactsFailed(SafetyProblem.of(error));
      case MutationUnknown<EmergencyContact>(:final error):
        _state.value = ContactsFailed(SafetyProblem.of(error));
      default:
        break;
    }
    return false;
  }

  Mutation<EmergencyContact> _addMutationFor(String name, String phone) {
    final signature = '$name|$phone';
    final existing = _addMutation;
    if (existing != null && _addSignature == signature) return existing;
    existing?.dispose();
    _addSignature = signature;
    return _addMutation = Mutation<EmergencyContact>(
      intent: IdempotencyIntent.safetyContact,
      run: (key) async {
        final response = await _api.post(
          SafetyEndpoints.contacts,
          data: {'name': name, 'phone': phone},
          key: key,
          suppressErrorToast: true,
        );
        return EmergencyContact.fromJson(response.dataMapOrEmpty);
      },
      reconcile: () async {
        final response = await _api.get(SafetyEndpoints.contacts, suppressErrorToast: true);
        final found = _contactsOf(response.dataMapOrEmpty).where((contact) => contact.phone == phone).firstOrNull;
        return found == null ? const ReconciledNotDone() : ReconciledDone(found);
      },
    );
  }

  void _releaseAdd() {
    _addMutation?.dispose();
    _addMutation = null;
    _addSignature = null;
  }

  Future<bool> remove(String id) async {
    final current = _centre.centre;
    if (current == null || isBusy) return false;
    if (LiveProblem.isOffline) {
      LiveProblem.toastOffline();
      return false;
    }
    _state.value = ContactsRemoving(id);
    try {
      await _api.delete(SafetyEndpoints.contactOf(id), suppressErrorToast: true);
      _centre.applyContacts([
        for (final contact in (_centre.centre ?? current).contacts)
          if (contact.id != id) contact,
      ]);
      _state.value = const ContactsIdle();
      return true;
    } catch (e) {
      log('remove contact failed: $e');
      _state.value = const ContactsIdle();
      if (e is ApiException && e.isNotFound) {
        unawaited(reloadContacts());
        return true;
      }
      SangaToast.show(SafetyProblem.of(e).message, tone: SangaToastTone.error);
      return false;
    }
  }

  List<EmergencyContact> _contactsOf(Map<String, dynamic> data) =>
      JsonReader.of(data).listOf('contacts', (contact) => EmergencyContact.fromJson(contact.raw));
}
