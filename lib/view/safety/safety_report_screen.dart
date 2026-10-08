import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/safety/safety_report_controller.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/safety/widgets/report_category_chips.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SafetyReportScreen extends StatefulWidget {
  const SafetyReportScreen({super.key, this.tripId});

  final String? tripId;

  @override
  State<SafetyReportScreen> createState() => _SafetyReportScreenState();
}

class _SafetyReportScreenState extends State<SafetyReportScreen> {
  final _report = Get.find<SafetyReportController>();
  final _details = TextEditingController();
  ReportCategory? _category;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report.reset());
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  bool get _isReady => SafetyReportRules.isReady(_category, _details.text);

  bool get _showsLengthHint {
    final length = _details.text.trim().length;
    return length > 0 && length < SafetyReportRules.minDetailsLength;
  }

  Future<void> _submit() async {
    final category = _category;
    if (category == null) return;
    FocusScope.of(context).unfocus();
    final receipt = await _report.submit(tripId: widget.tripId, category: category, details: _details.text);
    if (!mounted) return;
    if (receipt == null) {
      if (_report.state case ReportFailed(:final problem)) Toast.error(problem.message);
      return;
    }
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: 'Report sent',
      message: 'Thanks for telling us. Your reference is ${receipt.reference}.',
      actionLabel: 'Done',
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Report an issue',
      footer: Obx(
        () => ListenableBuilder(
          listenable: _details,
          builder: (context, _) => SangaButton.primary(
            label: 'Submit report',
            isLoading: _report.state is ReportSubmitting,
            onPressed: _isReady ? _submit : null,
          ),
        ),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.lg,
          children: [
            const Text(
              'Tell our safety team what happened. We take every report seriously.',
              style: SangaTextStyles.body,
            ),
            ReportCategoryChips(selected: _category, onSelected: (category) => setState(() => _category = category)),
            ListenableBuilder(
              listenable: _details,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: SangaSpacing.xs,
                children: [
                  SangaTextArea(
                    label: 'What happened?',
                    controller: _details,
                    hintText: 'Share as much as you can',
                    maxLength: SafetyReportRules.maxDetailsLength,
                    minLines: 5,
                  ),
                  if (_showsLengthHint)
                    Text(
                      'Add a bit more, at least ${SafetyReportRules.minDetailsLength} characters.',
                      style: SangaTextStyles.caption,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
