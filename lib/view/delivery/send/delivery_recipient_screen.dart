import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/router/delivery_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/who_for/widgets/passenger_gender_picker.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _Field { name, email, phone }

class DeliveryRecipientScreen extends StatefulWidget {
  const DeliveryRecipientScreen({super.key, required this.isEditing});

  final bool isEditing;

  @override
  State<DeliveryRecipientScreen> createState() => _DeliveryRecipientScreenState();
}

class _DeliveryRecipientScreenState extends State<DeliveryRecipientScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _delivery = Get.find<SendDeliveryController>();
  late final _name = TextEditingController(text: _delivery.draft.recipient?.name);
  late final _email = TextEditingController(text: _delivery.draft.recipient?.email);
  late final _phone = TextEditingController(text: _initialPhone());
  late PassengerGender? _gender = _delivery.draft.recipient?.gender;
  var _errors = <_Field, String>{};

  String _initialPhone() {
    final phone = _delivery.draft.recipient?.phone;
    return phone == null ? '' : SangaPhoneNumber.format(phone);
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearError(_Field field) {
    if (field == _Field.phone) _delivery.clearRecipientFailure();
    if (_errors.containsKey(field)) setState(() => _errors = {..._errors}..remove(field));
  }

  Map<_Field, String> _validate() {
    final email = _email.text.trim();
    return {
      if (_name.text.trim().isEmpty) _Field.name: 'Add the recipient’s name',
      if (email.isNotEmpty && !_emailPattern.hasMatch(email)) _Field.email: 'Enter a valid email or leave it blank',
      if (!SangaPhoneNumber.isValid(_phone.text)) _Field.phone: CommonCopy.invalidPhone,
    };
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final errors = _validate();
    if (errors.isNotEmpty) return setState(() => _errors = errors);
    final email = _email.text.trim();
    _delivery.setRecipient(
      BookingRecipient(
        name: _name.text.trim(),
        phone: SangaPhoneNumber.toE164(_phone.text),
        email: email.isEmpty ? null : email,
        gender: _gender,
      ),
    );
    DeliveryRoutes.advance(context, next: DeliveryRoutes.review, isEditing: widget.isEditing);
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Recipient info',
      subtitle: 'Who should your driver hand it to?',
      footer: SangaButton.primary(label: widget.isEditing ? 'Save' : 'Continue', onPressed: _submit),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            SangaTextField(
              label: 'Name',
              isRequired: true,
              hintText: 'Enter the recipient’s full name',
              controller: _name,
              errorText: _errors[_Field.name],
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              inputFormatters: [LengthLimitingTextInputFormatter(DeliveryRules.recipientNameMaxLength)],
              onChanged: (_) => _clearError(_Field.name),
            ),
            SangaTextField(
              label: 'Recipient’s email',
              hintText: 'Optional',
              controller: _email,
              errorText: _errors[_Field.email],
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _clearError(_Field.email),
            ),
            PassengerGenderPicker(selected: _gender, onChanged: (gender) => setState(() => _gender = gender)),
            Obx(
              () => SangaPhoneField(
                controller: _phone,
                errorText: _errors[_Field.phone] ?? _delivery.recipientFailure?.message,
                onChanged: (_) => _clearError(_Field.phone),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
