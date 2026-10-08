import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart' show Options;
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/safety_api.dart';
import 'package:sanga_ride/controller/rider/safety/safety_centre_controller.dart';
import 'package:sanga_ride/core/api/api.dart';
import 'package:sanga_ride/core/api/safety_endpoints.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';

class ContactsController extends GetxController {
  final _api = Get.find<ApiService>();
  final _centre = Get.find<SafetyCentreController>();

  final Rx<ContactsState> _state = Rx<ContactsState>(const ContactsIdle());

  Rx<ContactsState> get stateRx => _state;

  ContactsState get state => _state.value;

  bool get isBusy => state is ContactsAdding || state is ContactsRemoving;

  void reset() => _state.value = const ContactsIdle();

  void clearProblem() {
    if (state is ContactsFailed) _state.value = const ContactsIdle();
  }

  Future<void> reloadContacts() async {
    try {
      final response = await _api.get(SafetyEndpoints.contacts, suppressErrorToast: true);
      _centre.applyContacts(_contactsOf(safetyDataOf(response.data)));
    } catch (e) {
      log('contacts refresh failed: $e');
    }
  }

  Future<bool> add({required String name, required String phone}) async {
    final current = _centre.centre;
    if (current == null || isBusy) return false;
    _state.value = const ContactsAdding();
    try {
      final response = await _api.post(
        SafetyEndpoints.contacts,
        data: {'name': name, 'phone': phone},
        suppressErrorToast: true,
      );
      final created = EmergencyContact.fromJson(safetyDataOf(response.data));
      _centre.applyContacts([...(_centre.centre ?? current).contacts, created]);
      _state.value = const ContactsIdle();
      return true;
    } catch (e) {
      log('add contact failed: $e');
      _state.value = ContactsFailed(safetyProblemOf(e));
      return false;
    }
  }

  Future<bool> remove(String id) async {
    final current = _centre.centre;
    if (current == null || isBusy) return false;
    _state.value = ContactsRemoving(id);
    try {
      await _api.delete(SafetyEndpoints.contactOf(id), options: Options(extra: {'suppressErrorToast': true}));
      _centre.applyContacts([
        for (final contact in (_centre.centre ?? current).contacts)
          if (contact.id != id) contact,
      ]);
      _state.value = const ContactsIdle();
      return true;
    } catch (e) {
      log('remove contact failed: $e');
      _state.value = const ContactsIdle();
      Toast.error(safetyProblemOf(e).message);
      return false;
    }
  }

  List<EmergencyContact> _contactsOf(Map<String, dynamic> data) => [
    for (final contact in data['contacts'] as List)
      EmergencyContact.fromJson(Map<String, dynamic>.from(contact as Map)),
  ];
}
