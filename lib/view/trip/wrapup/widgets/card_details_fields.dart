import 'package:flutter/material.dart';
import 'package:sanga_ride/view/trip/wrapup/widgets/card_form_model.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class CardDetailsFields extends StatelessWidget {
  const CardDetailsFields({super.key, required this.model, required this.onDone});

  final CardFormModel model;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SangaSpacing.md,
        children: [
          SangaTextField(
            label: 'Card number',
            hintText: '0000 0000 0000 0000',
            isRequired: true,
            controller: model.controllerOf(CardField.number),
            focusNode: model.focusOf(CardField.number),
            errorText: model.errorOf(CardField.number),
            keyboardType: TextInputType.number,
            inputFormatters: [SangaCardNumberFormatter()],
            onSubmitted: (_) => model.focusAfter(CardField.number),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.md,
            children: [
              Expanded(
                child: SangaTextField(
                  label: 'Expiry date',
                  hintText: 'MM/YY',
                  isRequired: true,
                  controller: model.controllerOf(CardField.expiry),
                  focusNode: model.focusOf(CardField.expiry),
                  errorText: model.errorOf(CardField.expiry),
                  keyboardType: TextInputType.number,
                  inputFormatters: [SangaCardExpiryFormatter()],
                  onSubmitted: (_) => model.focusAfter(CardField.expiry),
                ),
              ),
              Expanded(
                child: SangaSecretField(
                  label: 'CVV',
                  hintText: '•••',
                  controller: model.controllerOf(CardField.cvv),
                  focusNode: model.focusOf(CardField.cvv),
                  errorText: model.errorOf(CardField.cvv),
                  maxDigits: CardFormModel.cvvLength,
                  onSubmitted: (_) => model.focusAfter(CardField.cvv),
                ),
              ),
            ],
          ),
          SangaSecretField(
            label: 'Card PIN',
            hintText: '••••',
            controller: model.controllerOf(CardField.pin),
            focusNode: model.focusOf(CardField.pin),
            errorText: model.errorOf(CardField.pin),
            maxDigits: CardFormModel.pinLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onDone(),
          ),
          const _SecurityNote(),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SangaSpacing.xs,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: SangaColors.textMuted),
        Expanded(
          child: Text(
            'Your card details go straight to our payment partner. We don’t store your PIN.',
            style: SangaTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
