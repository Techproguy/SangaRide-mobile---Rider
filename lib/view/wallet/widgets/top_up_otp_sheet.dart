import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/top_up_controller.dart';
import 'package:sanga_ride/model/wallet/wallet.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

Future<void> showTopUpOtpSheet({required BuildContext context, required TopUpController controller}) {
  return showSangaSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.xl, SangaSpacing.xxl, SangaSpacing.xl, SangaSpacing.xl),
    builder: (context) => PopScope(
      canPop: false,
      child: Obx(() {
        final state = controller.state;
        if (state is! TopUpOtp) return const SizedBox.shrink();
        return TopUpOtpContent(
          message: state.action.message,
          stage: state.stage,
          failureMessage: state.failure?.message,
          onSubmit: controller.submitOtp,
          onEdit: controller.editOtp,
          onCancel: controller.cancelOtp,
        );
      }),
    ),
  );
}

class TopUpOtpContent extends StatefulWidget {
  const TopUpOtpContent({
    super.key,
    required this.message,
    required this.stage,
    required this.onSubmit,
    this.failureMessage,
    required this.onEdit,
    required this.onCancel,
  });

  static const int codeLength = 4;
  static const String mismatchMessage = 'That code didn’t match. Check it and try again.';

  final String message;
  final OtpStage stage;
  final String? failureMessage;
  final ValueChanged<String> onSubmit;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  State<TopUpOtpContent> createState() => _TopUpOtpContentState();
}

class _TopUpOtpContentState extends State<TopUpOtpContent> {
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(_refresh);
  }

  @override
  void didUpdateWidget(TopUpOtpContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stage == OtpStage.mismatch && oldWidget.stage != OtpStage.mismatch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _code.clear();
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _changed(String value) {
    if (widget.stage != OtpStage.ready && widget.stage != OtpStage.verifying && value.isNotEmpty) widget.onEdit();
  }

  void _submit() {
    if (_code.text.length == TopUpOtpContent.codeLength) widget.onSubmit(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final isVerifying = widget.stage == OtpStage.verifying;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm with your bank', textAlign: TextAlign.center, style: SangaTextStyles.statusTitle),
        const SizedBox(height: SangaSpacing.xs),
        Text(widget.message, textAlign: TextAlign.center, style: SangaTextStyles.statusMessage),
        const SizedBox(height: SangaSpacing.lg),
        Center(
          child: SangaOtpField(
            length: TopUpOtpContent.codeLength,
            controller: _code,
            alignment: CrossAxisAlignment.center,
            errorText: widget.stage == OtpStage.mismatch ? TopUpOtpContent.mismatchMessage : null,
            onChanged: _changed,
            onCompleted: (_) => _submit(),
          ),
        ),
        if (widget.stage == OtpStage.failed && widget.failureMessage != null) ...[
          const SizedBox(height: SangaSpacing.md),
          SangaNotice(message: widget.failureMessage!, tone: SangaTone.warning),
        ],
        const SizedBox(height: SangaSpacing.xl),
        SangaButton.primary(
          label: 'Confirm',
          isLoading: isVerifying,
          onPressed: _code.text.length == TopUpOtpContent.codeLength ? _submit : null,
        ),
        const SizedBox(height: SangaSpacing.xs),
        SangaTextAction(label: 'Cancel', onPressed: isVerifying ? null : widget.onCancel),
      ],
    );
  }
}
