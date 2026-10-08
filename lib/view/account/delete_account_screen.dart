import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/account/account_controller.dart';
import 'package:sanga_ride/core/format/time_format.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const List<String> _consequences = [
    'Your account is scheduled for deletion and disappears after 30 days',
    'Log back in during those 30 days and your account stays right where it was',
    'Your ride history and saved places go with it',
    'Records we must keep by law stay with us',
  ];

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
    final isConfirmed = await showSangaPromptSheet(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'Delete your account?',
      message: 'This is the last step. You’ll be logged out right away.',
      actionLabel: 'Yes, delete it',
      dismissLabel: 'Keep my account',
    );
    if (!isConfirmed || !mounted) return;
    final isScheduled = await _controller.deleteAccount(reason: _reason?.code);
    if (!isScheduled || !mounted) return;
    final state = _controller.deleteState;
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: 'Deletion scheduled',
      message: state is DeleteScheduled
          ? 'Your account goes on ${TimeFormat.longDate(state.deletesAt)}. Log in before then to keep it.'
          : 'Log in within 30 days to keep your account.',
      actionLabel: 'Log out',
    );
    await _controller.logout();
  }

  Widget _block(AccountProblem problem) => SangaNotice(message: problem.message);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.deleteState;
      final isDeleting = state is DeleteDeleting;
      final block = state is DeleteIdle ? state.block : null;
      return SangaPageLayout(
        title: 'Delete account',
        footer: SangaButton.danger(
          label: 'Delete my account',
          isLoading: isDeleting,
          onPressed: _isUnderstood ? _confirm : null,
        ),
        children: [
          Text('Before you go', style: SangaTextStyles.title),
          const SizedBox(height: SangaSpacing.xs),
          Text('Here’s what happens when you delete your account.', style: SangaTextStyles.body),
          const SizedBox(height: SangaSpacing.lg),
          SangaSectionCard(
            title: 'What to expect',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SangaSpacing.md, vertical: SangaSpacing.xs),
                child: Column(
                  spacing: SangaSpacing.sm,
                  children: [
                    for (final line in _consequences)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: SangaSpacing.sm,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.circle, size: 6, color: SangaColors.textMuted),
                          ),
                          Expanded(child: Text(line, style: SangaTextStyles.cardSubtitle.copyWith(fontSize: 13))),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SangaSpacing.xl),
          const SangaSectionHeader('Why are you leaving? (optional)'),
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
            text: 'I understand my account will be deleted',
          ),
          if (block != null) ...[const SizedBox(height: SangaSpacing.lg), _block(block)],
        ],
      );
    });
  }
}
