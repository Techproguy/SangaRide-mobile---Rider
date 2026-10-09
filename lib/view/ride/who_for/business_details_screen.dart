import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/ride_for_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/who_for/widgets/business_paid_by_row.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  static const int purposeLimit = 80;
  static const int noteLimit = 120;

  final _flow = Get.find<RideForController>();
  final _purpose = TextEditingController();
  final _note = TextEditingController();
  late final BusinessProfile? _profile = _flow.pickedProfile;
  String? _purposeError;

  @override
  void initState() {
    super.initState();
    if (_profile == null) WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
    final current = _flow.rideFor;
    if (current is RideForBusiness && current.profile.id == _profile?.id) {
      _purpose.text = current.purpose;
      _note.text = current.note ?? '';
    }
  }

  @override
  void dispose() {
    _purpose.dispose();
    _note.dispose();
    super.dispose();
  }

  void _suggest(String purpose) {
    _purpose.text = purpose;
    _purpose.selection = TextSelection.collapsed(offset: purpose.length);
    setState(() => _purposeError = null);
  }

  void _confirm() {
    FocusScope.of(context).unfocus();
    final purpose = _purpose.text.trim();
    if (purpose.isEmpty) return setState(() => _purposeError = 'Say what the trip is for');
    final note = _note.text.trim();
    _flow.confirmBusiness(purpose: purpose, note: note.isEmpty ? null : note);
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) return const Scaffold();
    return SangaPageLayout(
      title: 'Business details',
      footer: SangaButton.primary(label: 'Confirm', onPressed: _confirm),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            BusinessPaidByRow(companyName: profile.companyName),
            SangaTextField(
              label: 'Trip purpose',
              isRequired: true,
              hintText: 'What is this trip for?',
              controller: _purpose,
              errorText: _purposeError,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(purposeLimit)],
              onChanged: (_) => setState(() => _purposeError = null),
            ),
            if (profile.purposes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SangaSpacing.xs,
                children: [
                  const Text('Used recently', style: SangaTextStyles.caption),
                  Wrap(
                    spacing: SangaSpacing.sm,
                    runSpacing: SangaSpacing.sm,
                    children: [
                      for (final purpose in profile.purposes)
                        SangaChoiceChip(
                          label: purpose,
                          isSelected: _purpose.text.trim() == purpose,
                          onSelected: (_) => _suggest(purpose),
                        ),
                    ],
                  ),
                ],
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
