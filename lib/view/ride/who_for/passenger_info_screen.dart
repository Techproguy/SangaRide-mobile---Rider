import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/core/router/who_for_routes.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/who_for/widgets/passenger_gender_picker.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _Field { name, email, phone }

class PassengerInfoScreen extends StatefulWidget {
  const PassengerInfoScreen({super.key});

  @override
  State<PassengerInfoScreen> createState() => _PassengerInfoScreenState();
}

class _PassengerInfoScreenState extends State<PassengerInfoScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _flow = Get.find<RideForController>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  PassengerGender? _gender;
  var _errors = <_Field, String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _flow.clearPassengerFlow());
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearError(_Field field) {
    if (field == _Field.phone) _flow.clearPassengerSendFailure();
    if (_errors.containsKey(field)) setState(() => _errors = {..._errors}..remove(field));
  }

  Map<_Field, String> _validate() {
    final email = _email.text.trim();
    return {
      if (_name.text.trim().isEmpty) _Field.name: 'Add the passenger’s name',
      if (email.isNotEmpty && !_emailPattern.hasMatch(email)) _Field.email: 'Enter a valid email or leave it blank',
      if (!SangaPhoneNumber.isValid(_phone.text)) _Field.phone: 'Enter a valid Nigerian phone number',
    };
  }

  String? _phoneError(PassengerFlowState state) {
    if (_errors[_Field.phone] case final error?) return error;
    if (state is! PassengerSendFailed) return null;
    return state.failure == PassengerFailure.connection ? null : state.failure.message;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final errors = _validate();
    if (errors.isNotEmpty) return setState(() => _errors = errors);
    final email = _email.text.trim();
    final info = PassengerInfo(
      name: _name.text.trim(),
      phone: SangaPhoneNumber.toE164(_phone.text),
      email: email.isEmpty ? null : email,
      gender: _gender,
    );
    final sent = await _flow.sendPassengerCode(info);
    if (!mounted) return;
    if (sent) return WhoForRoutes.continueTo(context, WhoForRoutes.passengerOtp);
    final state = _flow.passengerState;
    if (state is PassengerSendFailed && state.failure == PassengerFailure.connection) {
      Toast.error(state.failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Passenger’s info',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Send code',
          isLoading: _flow.passengerState is PassengerSending,
          onPressed: _submit,
        ),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            const Text('We’ll text them a code to make sure the number is right.', style: SangaTextStyles.body),
            SangaTextField(
              label: 'Name',
              isRequired: true,
              hintText: 'Enter the passenger’s full name',
              controller: _name,
              errorText: _errors[_Field.name],
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _clearError(_Field.name),
            ),
            SangaTextField(
              label: 'Passenger’s email',
              hintText: 'Enter the passenger’s email',
              controller: _email,
              errorText: _errors[_Field.email],
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _clearError(_Field.email),
            ),
            PassengerGenderPicker(selected: _gender, onChanged: (gender) => setState(() => _gender = gender)),
            Obx(
              () => SangaPhoneField(
                controller: _phone,
                errorText: _phoneError(_flow.passengerState),
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
