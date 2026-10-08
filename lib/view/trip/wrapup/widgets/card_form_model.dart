import 'package:flutter/widgets.dart';
import 'package:sanga_ride/model/trip/wrapup/wrapup.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum CardField { number, expiry, cvv, pin }

class CardFormModel extends ChangeNotifier {
  CardFormModel() {
    for (final field in CardField.values) {
      _controllers[field]!.addListener(() => _onEdited(field));
      _focusNodes[field]!.addListener(() => _onFocusChanged(field));
    }
  }

  static const int cvvLength = 3;
  static const int pinLength = 4;
  static const int standardNumberLength = 16;
  static const List<String> longNumberPrefixes = ['506', '650'];
  static const int expiryLength = 5;

  final Map<CardField, TextEditingController> _controllers = {
    for (final field in CardField.values) field: TextEditingController(),
  };
  final Map<CardField, FocusNode> _focusNodes = {for (final field in CardField.values) field: FocusNode()};
  final Set<CardField> _touched = {};
  final Map<CardField, int> _lengths = {for (final field in CardField.values) field: 0};

  TextEditingController controllerOf(CardField field) => _controllers[field]!;

  FocusNode focusOf(CardField field) => _focusNodes[field]!;

  String _textOf(CardField field) => _controllers[field]!.text;

  String get _digits => SangaCardNumberFormatter.digitsOf(_textOf(CardField.number));

  bool get isValid => CardField.values.every((field) => _problemWith(field) == null);

  String? errorOf(CardField field) => _touched.contains(field) ? _problemWith(field) : null;

  String? _problemWith(CardField field) => switch (field) {
    CardField.number => _numberProblem,
    CardField.expiry => _expiryProblem,
    CardField.cvv => _textOf(field).length == cvvLength ? null : 'Enter the 3 digits on the back of your card',
    CardField.pin => _textOf(field).length == pinLength ? null : 'Enter your 4 digit card PIN',
  };

  String? get _numberProblem {
    if (_digits.isEmpty) return 'Enter your card number';
    return SangaCardNumberFormatter.isValid(_digits) ? null : 'That card number doesn’t look right';
  }

  String? get _expiryProblem {
    final text = _textOf(CardField.expiry);
    if (text.isEmpty) return 'Enter the expiry date';
    if (SangaCardExpiryFormatter.isValid(text)) return null;
    if (text.length < expiryLength) return 'Use the MM/YY format';
    final month = int.parse(text.substring(0, 2));
    return month < 1 || month > 12 ? 'That month doesn’t exist' : 'That card has expired';
  }

  void _onEdited(CardField field) {
    final length = _textOf(field).length;
    final grew = length > _lengths[field]!;
    _lengths[field] = length;
    notifyListeners();
    if (grew && _isComplete(field)) _advanceFrom(field);
  }

  bool _isComplete(CardField field) => switch (field) {
    CardField.number =>
      _digits.length == standardNumberLength &&
          SangaCardNumberFormatter.isValid(_digits) &&
          !longNumberPrefixes.any(_digits.startsWith),
    CardField.expiry => SangaCardExpiryFormatter.isValid(_textOf(field)),
    CardField.cvv => _textOf(field).length == cvvLength,
    CardField.pin => false,
  };

  void _advanceFrom(CardField field) {
    final next = switch (field) {
      CardField.number => CardField.expiry,
      CardField.expiry => CardField.cvv,
      CardField.cvv => CardField.pin,
      CardField.pin => null,
    };
    if (next != null) focusOf(next).requestFocus();
  }

  void _onFocusChanged(CardField field) {
    if (_focusNodes[field]!.hasFocus || _textOf(field).isEmpty) return;
    _touched.add(field);
    notifyListeners();
  }

  void focusAfter(CardField field) => _advanceFrom(field);

  CardDetails? take() {
    if (!isValid) {
      _touched.addAll(CardField.values);
      notifyListeners();
      return null;
    }
    final details = CardDetails(
      number: _digits,
      expiry: _textOf(CardField.expiry),
      cvv: _textOf(CardField.cvv),
      pin: _textOf(CardField.pin),
    );
    clear();
    return details;
  }

  void clear() {
    _touched.clear();
    for (final controller in _controllers.values) {
      controller.clear();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}
