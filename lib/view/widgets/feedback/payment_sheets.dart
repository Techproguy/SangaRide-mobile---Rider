import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

const EdgeInsets _statusPadding = EdgeInsets.fromLTRB(
  SangaSpacing.xl,
  SangaSpacing.xxl,
  SangaSpacing.xl,
  SangaSpacing.xl,
);

class PaymentSheetSlot {
  int _generation = 0;
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  Future<T?> show<T>(Future<T?> Function() open) async {
    if (_isOpen) return null;
    _isOpen = true;
    final generation = ++_generation;
    final result = await open();
    if (generation == _generation) _isOpen = false;
    return result;
  }

  void close(BuildContext context) {
    if (!_isOpen) return;
    _isOpen = false;
    _generation++;
    Navigator.of(context).pop();
  }
}

Future<bool?> showPaymentPendingSheet({
  required BuildContext context,
  required String title,
  required String message,
  String? cancelLabel,
}) {
  return showSangaSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: _statusPadding,
    builder: (context) => PopScope(
      canPop: false,
      child: SangaStatusContent(
        status: SangaStatus.pending,
        title: title,
        message: message,
        secondary: cancelLabel == null ? null : _SheetTextAction(label: cancelLabel, result: true),
      ),
    ),
  );
}

Future<bool?> showPaymentFailureSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String primaryLabel,
  required String secondaryLabel,
}) {
  return showSangaSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: _statusPadding,
    builder: (context) => PopScope(
      canPop: false,
      child: SangaStatusContent(
        status: SangaStatus.failure,
        title: title,
        message: message,
        action: SangaButton.primary(label: primaryLabel, onPressed: () => Navigator.of(context).pop(true)),
        secondary: _SheetTextAction(label: secondaryLabel, result: false),
      ),
    ),
  );
}

Future<void> showPaymentPaidSheet({required BuildContext context, required String title, required String message}) {
  return showSangaStatusSheet(
    context: context,
    status: SangaStatus.success,
    title: title,
    message: message,
    actionLabel: 'Continue',
  );
}

class _SheetTextAction extends StatelessWidget {
  const _SheetTextAction({required this.label, required this.result});

  final String label;
  final bool result;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(result),
      child: Text(label, style: SangaTextStyles.label.copyWith(color: SangaColors.primary)),
    );
  }
}
