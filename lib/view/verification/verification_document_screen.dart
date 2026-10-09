import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/account/verification_controller.dart';
import 'package:sanga_ride/core/router/verification_routes.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/send/widgets/photo_source_sheet.dart';
import 'package:sanga_ride/view/verification/verification_copy.dart';
import 'package:sanga_ride/view/verification/widgets/document_slot.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class VerificationDocumentScreen extends StatefulWidget {
  const VerificationDocumentScreen({super.key});

  @override
  State<VerificationDocumentScreen> createState() => _VerificationDocumentScreenState();
}

class _VerificationDocumentScreenState extends State<VerificationDocumentScreen> {
  final _controller = Get.find<VerificationController>();
  final _permissions = Get.find<PermissionCenter>();
  final List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    for (final kind in [PermissionKind.camera, PermissionKind.photos]) {
      _workers.add(ever(_permissions.statusRx(kind), _onPermissionChanged));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.startDocument();
    });
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.releaseDocument());
    super.dispose();
  }

  void _onPermissionChanged(PermissionAccess access) {
    if (access.isUsable) _controller.clearPermissionFailures();
  }

  Future<void> _pick(DocumentSide side) async {
    if (_controller.draft.sideOf(side).isBusy) return;
    final source = await showPhotoSourceSheet(context, title: VerificationCopy.addYourId);
    if (source == null || !mounted) return;
    if (source == PhotoSource.camera) await _permissions.prime(PermissionKind.camera, context);
    if (mounted) await _controller.pickPhoto(side, source);
  }

  Future<void> _takeSelfie() async {
    final hasPassed = await context.push<bool>(VerificationRoutes.selfie);
    if (hasPassed == true && mounted) await _submit();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final isSent = await _controller.submitDocument();
    if (!mounted) return;
    if (!isSent) {
      if (_controller.draft.missing.contains(VerificationItemKind.selfie.code)) await _takeSelfie();
      return;
    }
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.pending,
      title: VerificationCopy.underReviewTitle,
      message: VerificationCopy.underReviewMessage(_controller.state.verificationOrNull?.estimatedReviewHours ?? 24),
      actionLabel: VerificationCopy.done,
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
      onOpenSettings: _permissions.openSettings,
    );
  }

  Widget _problem(DocumentDraft draft) {
    final problem = draft.problem;
    if (problem == null) return const SizedBox.shrink();
    final isSelfieMissing = draft.missing.contains(VerificationItemKind.selfie.code);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.sm,
      children: [
        if (isSelfieMissing)
          const SangaNotice(
            tone: SangaTone.neutral,
            icon: Icons.photo_camera_front_outlined,
            message: VerificationCopy.idSavedTakeSelfie,
          )
        else
          SangaNotice(message: problem.message),
        if (isSelfieMissing)
          SangaButton.outline(
            label: VerificationCopy.takeYourSelfie,
            size: SangaButtonSize.compact,
            onPressed: () => unawaited(_takeSelfie()),
          ),
      ],
    );
  }

  List<Widget> _children(DocumentDraft draft) {
    final type = draft.type;
    return [
      SangaSelectField<IdDocumentType>(
        label: VerificationCopy.documentType,
        isRequired: true,
        value: type,
        options: [for (final option in _controller.documentTypes) SangaSelectOption(option, option.label)],
        onChanged: _controller.selectType,
      ),
      const SizedBox(height: SangaSpacing.md),
      if (type == null)
        Text(VerificationCopy.pickIdLead, style: SangaTextStyles.body)
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.md,
          children: [
            Text(type.hint, style: SangaTextStyles.body),
            _slot(draft, DocumentSide.front, type.frontLabel),
            if (type.hasBack) _slot(draft, DocumentSide.back, VerificationCopy.backOfId),
            if (_controller.documentItem?.uploadRules case final rules?)
              Text(rules.summary, style: SangaTextStyles.caption),
          ],
        ),
      const SizedBox(height: SangaSpacing.lg),
      const SangaNotice(
        tone: SangaTone.neutral,
        icon: Icons.lock_outline_rounded,
        message: VerificationCopy.informationSecure,
      ),
      const SizedBox(height: SangaSpacing.md),
      _problem(draft),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final draft = _controller.draft;
      return SangaPageLayout(
        title: VerificationCopy.documentVerification,
        footer: SangaButton.primary(
          label: VerificationCopy.submitForReview,
          isLoading: draft.isSubmitting,
          onPressed: draft.isReady ? _submit : null,
        ),
        children: [
          Text(VerificationCopy.uploadValidId, style: SangaTextStyles.body),
          const SizedBox(height: SangaSpacing.lg),
          ..._children(draft),
        ],
      );
    });
  }
}
