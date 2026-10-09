import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/safety/contacts_controller.dart';
import 'package:sanga_ride/controller/rider/safety/safety_centre_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/safety/widgets/dial_number.dart';
import 'package:sanga_ride/view/safety/widgets/emergency_contacts_card.dart';
import 'package:sanga_ride/view/safety/widgets/remove_contact.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/wrapup_async_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  static const int _minNameLength = 2;
  static const int _maxNameLength = 40;

  final _centre = Get.find<SafetyCentreController>();
  final _contacts = Get.find<ContactsController>();
  final _phone = TextEditingController();
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contacts.reset();
      unawaited(_contacts.reloadContacts());
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _isValid => SangaPhoneNumber.isValid(_phone.text) && _name.text.trim().length >= _minNameLength;

  String? _phoneError(ContactsState state) {
    if (state is ContactsFailed && state.problem.isPhoneProblem) return state.problem.message;
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    final isAdded = await _contacts.add(name: name, phone: SangaPhoneNumber.toE164(_phone.text));
    if (!mounted) return;
    if (isAdded) {
      _name.clear();
      _phone.clear();
      SangaToast.show('$name is now an emergency contact', tone: SangaToastTone.success);
      return;
    }
    final state = _contacts.state;
    if (state is! ContactsFailed || state.problem.isPhoneProblem) return;
    SangaToast.show(state.problem.message, tone: SangaToastTone.error);
    if (state.problem == SafetyProblem.contactsLimit) unawaited(_contacts.reloadContacts());
  }

  Widget _form(ContactsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        Text('Add new contact', style: SangaTextStyles.titleSmall),
        SangaPhoneField(
          controller: _phone,
          errorText: _phoneError(state),
          onChanged: (_) {
            _contacts.clearProblem();
            setState(() {});
          },
        ),
        SangaTextField(
          label: 'Name',
          isRequired: true,
          hintText: 'Adeyemo Silver',
          controller: _name,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          inputFormatters: [LengthLimitingTextInputFormatter(_maxNameLength)],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_isValid) unawaited(_submit());
          },
        ),
      ],
    );
  }

  Widget _body(SafetyCentre centre, ContactsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.xl,
      children: [
        EmergencyContactsCard(
          contacts: centre.contacts,
          removingId: state is ContactsRemoving ? state.id : null,
          onCall: (contact) => unawaited(dialNumber(contact.phone)),
          onRemove: (contact) => unawaited(confirmRemoveContact(context, contact)),
        ),
        if (centre.canAddContact)
          _form(state)
        else
          const SangaNotice(
            message: 'You’ve added the most contacts you can. Remove one to add another.',
            tone: SangaTone.neutral,
            icon: Icons.info_outline_rounded,
          ),
      ],
    );
  }

  Widget? _footer(SafetyCentre? centre, ContactsState state) {
    if (centre == null || !centre.canAddContact) return null;
    return SangaButton.primary(label: 'Add', isLoading: state is ContactsAdding, onPressed: _isValid ? _submit : null);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final centreState = _centre.state;
      final contactsState = _contacts.state;
      final centre = _centre.centre;
      return SangaPageLayout(
        title: 'Emergency contacts',
        footer: _footer(centre, contactsState),
        children: [
          WrapUpAsyncBody(
            isLoading: centreState is SafetyCentreLoading,
            failure: switch (centreState) {
              SafetyCentreFailed(:final problem) => WrapUpFailure(
                title: 'We couldn’t load your contacts',
                message: problem.message,
                onRetry: () => unawaited(_centre.retry()),
              ),
              SafetyCentreLoading() || SafetyCentreLoaded() => null,
            },
            skeletonHeights: const [150, 44, 44],
            builder: (_) => centre == null ? const SizedBox.shrink() : _body(centre, contactsState),
          ),
        ],
      );
    });
  }
}
