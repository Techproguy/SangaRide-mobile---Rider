import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/who_for/widgets/business_paid_by_row.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _Field { purpose, costCentre }

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  static const int noteLimit = 120;

  final _flow = Get.find<RideForController>();
  final _costCentre = TextEditingController();
  final _note = TextEditingController();
  late final BusinessProfile? _profile = _flow.pickedProfile;
  String? _purpose;
  var _errors = <_Field, String>{};

  @override
  void initState() {
    super.initState();
    if (_profile == null) WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
    final current = _flow.rideFor;
    if (current is RideForBusiness && current.profile.id == _profile?.id) {
      _purpose = current.purpose;
      _costCentre.text = current.costCentre ?? '';
      _note.text = current.note ?? '';
    }
  }

  @override
  void dispose() {
    _costCentre.dispose();
    _note.dispose();
    super.dispose();
  }

  void _clearError(_Field field) {
    if (_errors.containsKey(field)) setState(() => _errors = {..._errors}..remove(field));
  }

  Map<_Field, String> _validate(BusinessProfile profile) => {
    if (_purpose == null) _Field.purpose: 'Pick what the trip is for',
    if (profile.requiresCostCentre && _costCentre.text.trim().isEmpty)
      _Field.costCentre: '${profile.companyName} needs a cost centre',
  };

  void _confirm(BusinessProfile profile) {
    FocusScope.of(context).unfocus();
    final errors = _validate(profile);
    if (errors.isNotEmpty) return setState(() => _errors = errors);
    final costCentre = _costCentre.text.trim();
    final note = _note.text.trim();
    _flow.confirmBusiness(
      purpose: _purpose!,
      costCentre: costCentre.isEmpty ? null : costCentre,
      note: note.isEmpty ? null : note,
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) return const Scaffold();
    return SangaPageLayout(
      title: 'Business details',
      footer: SangaButton.primary(label: 'Confirm', onPressed: () => _confirm(profile)),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            BusinessPaidByRow(companyName: profile.companyName),
            SangaSelectField<String>(
              label: 'Trip purpose',
              isRequired: true,
              hintText: 'Choose a purpose',
              value: _purpose,
              errorText: _errors[_Field.purpose],
              options: [for (final purpose in profile.purposes) SangaSelectOption(purpose, purpose)],
              onChanged: (purpose) {
                _clearError(_Field.purpose);
                setState(() => _purpose = purpose);
              },
            ),
            if (profile.requiresCostCentre)
              SangaTextField(
                label: 'Cost centre',
                isRequired: true,
                hintText: 'Enter your cost centre',
                controller: _costCentre,
                errorText: _errors[_Field.costCentre],
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => _clearError(_Field.costCentre),
              ),
            SangaTextArea(
              label: 'Additional details (optional)',
              hintText: 'Write details',
              controller: _note,
              maxLength: noteLimit,
              minLines: 3,
            ),
          ],
        ),
      ],
    );
  }
}
