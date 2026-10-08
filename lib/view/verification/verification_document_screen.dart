import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/verification_controller.dart';
import 'package:sanga_ride/core/router/verification_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/send/widgets/photo_source_sheet.dart';
import 'package:sanga_ride/view/verification/widgets/document_slot.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerificationDocumentScreen extends StatefulWidget {
  const VerificationDocumentScreen({super.key});

  @override
  State<VerificationDocumentScreen> createState() => _VerificationDocumentScreenState();
}

class _VerificationDocumentScreenState extends State<VerificationDocumentScreen> {
  final _controller = Get.find<VerificationController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.startDocument();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.releaseDocument());
    super.dispose();
  }

  Future<void> _pick(DocumentSide side) async {
    if (_controller.draft.sideOf(side).isBusy) return;
    final source = await showPhotoSourceSheet(context, title: 'Add your ID');
    if (source != null) await _controller.pickPhoto(side, source);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final isSent = await _controller.submitDocument();
    if (!isSent || !mounted) return;
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.pending,
      title: 'Verification under review',
      message: 'This usually takes up to 24 hours. We’ll let you know in your notifications.',
      actionLabel: 'Done',
    );
    if (mounted) context.pop();
  }

  Widget _slot(DocumentDraft draft, DocumentSide side, String label) {
    return DocumentSlot(
      label: label,
      state: draft.sideOf(side),
      onPick: () => _pick(side),
      onRemove: () => _controller.removePhoto(side),
      onRetry: () => _controller.retryUpload(side),
      onOpenSettings: Geolocator.openAppSettings,
    );
  }

  Widget _problem(DocumentDraft draft) {
    final problem = draft.problem;
    if (problem == null) return const SizedBox.shrink();
    final isSelfieMissing = draft.missing.contains('selfie');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        SangaNotice(
          message: isSelfieMissing ? 'Your ID is saved. Take your selfie and we’ll send it all off.' : problem.message,
        ),
        if (isSelfieMissing)
          SangaButton.outline(
            label: 'Take your selfie',
            size: SangaButtonSize.compact,
            onPressed: () => context.push(VerificationRoutes.selfie),
          ),
      ],
    );
  }

  List<Widget> _children(DocumentDraft draft) {
    final type = draft.type;
    return [
      SangaSelectField<IdDocumentType>(
        label: 'Document type',
        isRequired: true,
        value: type,
        options: [for (final option in IdDocumentType.values) SangaSelectOption(option, option.label)],
        onChanged: _controller.selectType,
      ),
      const SizedBox(height: SangaSpacing.md),
      if (type == null)
        Text('Pick the ID you want to use and we’ll show you what to upload.', style: SangaTextStyles.body)
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.md,
          children: [
            Text(type.hint, style: SangaTextStyles.body),
            _slot(draft, DocumentSide.front, type.frontLabel),
            if (type.hasBack) _slot(draft, DocumentSide.back, 'Back of ID'),
            Text('Accepted formats: JPG or PNG, up to 5MB each', style: SangaTextStyles.caption),
          ],
        ),
      const SizedBox(height: SangaSpacing.lg),
      const SangaNotice(
        tone: SangaTone.neutral,
        icon: Icons.lock_outline_rounded,
        message: 'Your information is secure and only used for verification.',
      ),
      const SizedBox(height: SangaSpacing.md),
      _problem(draft),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final draft = _controller.draft;
      return SangaFormLayout(
        title: 'Document verification',
        subtitle: 'Upload a valid ID',
        footer: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.gutter),
          child: SangaButton.primary(
            label: 'Submit for review',
            isLoading: draft.isSubmitting,
            onPressed: draft.isReady ? _submit : null,
          ),
        ),
        children: _children(draft),
      );
    });
  }
}
