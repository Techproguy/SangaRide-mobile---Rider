import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum ProfileField { name, email, birthday }

Future<void> showProfileEditSheet(BuildContext context, {required ProfileField field, required Account account}) {
  return showSangaSheet<void>(
    context: context,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.xl, SangaSpacing.xxl, SangaSpacing.xl, SangaSpacing.xl),
    builder: (context) => _ProfileEditSheet(field: field, account: account),
  );
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({required this.field, required this.account});

  final ProfileField field;
  final Account account;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _isoDay = DateFormat('yyyy-MM-dd');

  final _account = Get.find<AccountController>();
  late final _firstName = TextEditingController(text: widget.account.firstName);
  late final _lastName = TextEditingController(text: widget.account.lastName);
  late final _email = TextEditingController(text: widget.account.email ?? '');
  late DateTime? _birthday = widget.account.dateOfBirth;
  AccountProblem? _problem;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  String get _title => switch (widget.field) {
    ProfileField.name => 'Your name',
    ProfileField.email => 'Your email',
    ProfileField.birthday => 'Your birthday',
  };

  AccountProblem? _localProblem() => switch (widget.field) {
    ProfileField.name =>
      _firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty ? AccountProblem.nameRequired : null,
    ProfileField.email => _emailPattern.hasMatch(_email.text.trim()) ? null : AccountProblem.invalidEmail,
    ProfileField.birthday => null,
  };

  Map<String, dynamic> get _fields => switch (widget.field) {
    ProfileField.name => {'firstName': _firstName.text.trim(), 'lastName': _lastName.text.trim()},
    ProfileField.email => {'email': _email.text.trim()},
    ProfileField.birthday => {'dateOfBirth': _isoDay.format(_birthday!)},
  };

  bool get _canSave => widget.field != ProfileField.birthday || _birthday != null;

  void _clearProblem() {
    if (_problem != null) setState(() => _problem = null);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final local = _localProblem();
    if (local != null) return setState(() => _problem = local);
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _problem = null;
    });
    final problem = await _account.saveProfile(_fields);
    if (!mounted) return;
    if (problem == null) {
      Navigator.of(context).pop();
      return SangaToast.show('Profile updated', tone: SangaToastTone.success);
    }
    setState(() {
      _isSaving = false;
      _problem = problem;
    });
  }

  Widget _input() {
    final message = _problem?.message;
    return switch (widget.field) {
      ProfileField.name => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.md,
            children: [
              Expanded(
                child: SangaTextField(
                  label: 'First name',
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  onChanged: (_) => _clearProblem(),
                ),
              ),
              Expanded(
                child: SangaTextField(
                  label: 'Last name',
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.familyName],
                  onChanged: (_) => _clearProblem(),
                  onSubmitted: (_) => _save(),
                ),
              ),
            ],
          ),
          SangaFieldError(message),
        ],
      ),
      ProfileField.email => SangaTextField(
        label: 'Email address',
        controller: _email,
        errorText: message,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        onChanged: (_) => _clearProblem(),
        onSubmitted: (_) => _save(),
      ),
      ProfileField.birthday => SangaBirthdayField(
        minimumAge: 16,
        initialDate: _birthday,
        errorText: message,
        onPicked: (date) => setState(() {
          _birthday = date;
          _problem = null;
        }),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_title, textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        const SizedBox(height: SangaSpacing.lg),
        _input(),
        const SizedBox(height: SangaSpacing.xl),
        SangaButton.primary(label: 'Save', isLoading: _isSaving, onPressed: _canSave ? _save : null),
      ],
    );
  }
}
