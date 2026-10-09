import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/account/account_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _controller = Get.find<AccountController>();
  DeleteReason? _reason;
  bool _isUnderstood = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.resetDelete();
    });
  }

  Future<void> _confirm() async {
    final isConfirmed = await showSangaStatusSheet(
      context: context,
      status: SangaStatus.caution,
      icon: Icons.delete_outline_rounded,
      title: AccountCopy.deleteConfirmTitle,
      message: AccountCopy.deleteConfirmMessage,
      actionLabel: AccountCopy.deleteConfirmAction,
      secondaryLabel: AccountCopy.keepMyAccount,
      isDestructive: true,
    );
    if (!isConfirmed || !mounted) return;
    final isScheduled = await _controller.deleteAccount(reason: _reason?.code);
    if (!isScheduled || !mounted) return;
    await _announceAndLogOut();
  }

  Future<void> _announceAndLogOut() async {
    final state = _controller.deleteState;
    final deletesAt = state is DeleteScheduled ? state.deletesAt : null;
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: AccountCopy.deletionScheduled,
      message: deletesAt != null
          ? AccountCopy.deletionDate(TimeFormat.longDate(deletesAt))
          : AccountCopy.deletionWindow,
      actionLabel: AccountCopy.logOut,
    );
    await _controller.logout();
  }

  Widget _footer(DeleteAccountState state) {
    return SangaButton.danger(
      label: state is DeleteUnknown ? AccountCopy.checkAgain : AccountCopy.deleteMyAccount,
      isLoading: state is DeleteDeleting,
      onPressed: state is DeleteUnknown ? () => unawaited(_checkAgain()) : (_isUnderstood ? _confirm : null),
    );
  }

  Future<void> _checkAgain() async {
    final isScheduled = await _controller.deleteAccount();
    if (isScheduled && mounted) await _announceAndLogOut();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.deleteState;
      final block = state is DeleteIdle ? state.block : null;
      return SangaPageLayout(
        title: AccountCopy.deleteAccount,
        footer: _footer(state),
        children: [
          Text(AccountCopy.beforeYouGo, style: SangaTextStyles.title),
          const SizedBox(height: SangaSpacing.xs),
          Text(AccountCopy.deleteLead, style: SangaTextStyles.body),
          const SizedBox(height: SangaSpacing.lg),
          SangaSectionCard(
            title: AccountCopy.whatToExpect,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.xs),
                child: Column(spacing: SangaSpacing.sm, children: [for (final line in AccountCopy.deletionConsequences) _Bullet(line)]),
              ),
            ],
          ),
          const SizedBox(height: SangaSpacing.xl),
          const SangaSectionHeader(AccountCopy.whyLeaving),
          const SizedBox(height: SangaSpacing.sm),
          SangaChoiceChips<DeleteReason>(
            options: [for (final reason in DeleteReason.values) SangaSelectOption(reason, reason.label)],
            value: _reason,
            onChanged: (reason) => setState(() => _reason = reason),
          ),
          const SizedBox(height: SangaSpacing.xl),
          SangaCheckRow.text(
            isChecked: _isUnderstood,
            onChanged: (value) => setState(() => _isUnderstood = value),
            text: AccountCopy.understandDeletion,
          ),
          if (block != null) ...[const SizedBox(height: SangaSpacing.lg), SangaNotice(message: block.message)],
          if (state is DeleteUnknown) ...[
            const SizedBox(height: SangaSpacing.lg),
            SangaNotice(message: AccountProblem.deleteUnconfirmed.message, tone: SangaTone.warning),
          ],
        ],
      );
    });
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.sm,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: SangaSpacing.xxs),
          child: Icon(Icons.circle, size: 6, color: SangaColors.textMuted),
        ),
        Expanded(child: Text(text, style: SangaTextStyles.cardBody)),
      ],
    );
  }
}
