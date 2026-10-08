import 'package:flutter/material.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class BookingPickerField extends StatefulWidget {
  const BookingPickerField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.onTap,
    this.value,
    this.errorText,
    this.trailing,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final VoidCallback onTap;
  final String? value;
  final String? errorText;
  final Widget? trailing;

  @override
  State<BookingPickerField> createState() => _BookingPickerFieldState();
}

class _BookingPickerFieldState extends State<BookingPickerField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(BookingPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _controller.text = widget.value ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SangaTextField(
      label: widget.label,
      hintText: widget.hintText,
      controller: _controller,
      errorText: widget.errorText,
      onTap: () {
        FocusScope.of(context).unfocus();
        widget.onTap();
      },
      trailing: widget.trailing ?? Icon(widget.icon, color: SangaColors.textMuted),
    );
  }
}
