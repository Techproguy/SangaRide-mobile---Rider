import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/contacts_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> confirmRemoveContact(BuildContext context, EmergencyContact contact) async {
  final isConfirmed = await showSangaPromptSheet(
    context: context,
    icon: Icons.person_remove_rounded,
    title: 'Remove ${contact.name}?',
    message: 'They won’t be alerted if you use SOS.',
    actionLabel: 'Remove',
    dismissLabel: 'Keep',
  );
  if (isConfirmed) await Get.find<ContactsController>().remove(contact.id);
}
