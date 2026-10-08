import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanga_ride/model/location/place.dart';
import 'package:sanga_ride/model/places/saved_place.dart';
import 'package:sanga_ride/view/places/widgets/place_field_tile.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SavedPlaceForm extends StatefulWidget {
  const SavedPlaceForm({
    super.key,
    required this.kind,
    required this.book,
    required this.isSaving,
    required this.submitLabel,
    required this.locationPlaceholder,
    required this.onPickLocation,
    required this.onSubmit,
    this.locationHint,
    this.editing,
  });

  final SavedPlaceKind kind;
  final SavedPlaceBook book;
  final SavedPlace? editing;
  final bool isSaving;
  final String submitLabel;
  final String locationPlaceholder;
  final String? locationHint;
  final Future<Place?> Function() onPickLocation;
  final Future<bool> Function(String label, Place place) onSubmit;

  @override
  State<SavedPlaceForm> createState() => _SavedPlaceFormState();
}

class _SavedPlaceFormState extends State<SavedPlaceForm> {
  late final _name = TextEditingController(text: widget.editing?.label ?? '');
  late Place? _place = widget.editing?.place;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _asksForName => !widget.kind.isSlot;

  String get _label => _asksForName ? _name.text.trim() : widget.kind.label;

  bool get _isTaken =>
      _asksForName && _label.isNotEmpty && widget.book.labelTaken(_label, exceptId: widget.editing?.id);

  bool get _hasChanged {
    final editing = widget.editing;
    if (editing == null) return true;
    return editing.label != _label || editing.place.placeId != _place?.placeId;
  }

  bool get _canSubmit =>
      !widget.isSaving && _place != null && (!_asksForName || _label.isNotEmpty) && !_isTaken && _hasChanged;

  Future<void> _pick() async {
    FocusScope.of(context).unfocus();
    final picked = await widget.onPickLocation();
    if (picked != null && mounted) setState(() => _place = picked);
  }

  Future<void> _submit() async {
    final place = _place;
    if (place == null || !_canSubmit) return;
    FocusScope.of(context).unfocus();
    final isSaved = await widget.onSubmit(_label, place);
    if (!isSaved || !mounted || widget.editing != null) return;
    _name.clear();
    setState(() => _place = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        if (_asksForName)
          SangaTextField(
            label: 'Name',
            hintText: 'Church, gym, mum’s place',
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            errorText: _isTaken ? 'You already have a place with that name' : null,
            inputFormatters: [LengthLimitingTextInputFormatter(SavedPlaceBook.maxLabelLength)],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        PlaceFieldTile(
          placeholder: widget.locationPlaceholder,
          hint: widget.locationHint,
          place: _place,
          pinColor: _asksForName ? SangaColors.pinDropoff : SangaColors.primary,
          onTap: widget.isSaving ? null : _pick,
        ),
        SangaButton.primary(
          label: widget.submitLabel,
          isLoading: widget.isSaving,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }
}
