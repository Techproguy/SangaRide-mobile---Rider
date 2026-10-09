import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/core/format/number_formats.dart';
import 'package:sanga_ride/core/router/delivery_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/send/widgets/delivery_catalog_gate.dart';
import 'package:sanga_ride/view/delivery/send/widgets/value_warning.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryValueScreen extends StatefulWidget {
  const DeliveryValueScreen({super.key, required this.isEditing});

  final bool isEditing;

  @override
  State<DeliveryValueScreen> createState() => _DeliveryValueScreenState();
}

class _DeliveryValueScreenState extends State<DeliveryValueScreen> {
  final _delivery = Get.find<SendDeliveryController>();
  late final _value = TextEditingController(text: _initialText());

  String _initialText() {
    final value = _delivery.draft.declaredValue;
    return value == null ? '' : NumberFormats.groupedNigeria.format(value);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _delivery.loadCatalog());
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    DeliveryRoutes.advance(context, next: DeliveryRoutes.route, isEditing: widget.isEditing);
  }

  void _skip() {
    _delivery.setDeclaredValue(null);
    _next();
  }

  bool _isValid(DeliveryCatalog? catalog) {
    final value = _delivery.draft.declaredValue;
    return catalog != null && value != null && value > 0 && value <= catalog.maxDeclaredValue;
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Declare value',
      subtitle: 'Tell us what it’s worth',
      footer: Obx(() {
        final hasValue = _delivery.draft.declaredValue != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: SangaSpacing.sm,
          children: [
            SangaButton.primary(
              label: widget.isEditing ? 'Save' : 'Continue',
              onPressed: _isValid(_delivery.catalog) ? _next : null,
            ),
            SangaButton.outline(
              label: widget.isEditing && hasValue ? 'Remove value' : 'Skip for now',
              onPressed: _skip,
            ),
          ],
        );
      }),
      children: [DeliveryCatalogGate(builder: (context, catalog) => Obx(() => _body(catalog)))],
    );
  }

  Widget _body(DeliveryCatalog catalog) {
    final value = _delivery.draft.declaredValue;
    final isTooHigh = value != null && value > catalog.maxDeclaredValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SangaSpacing.xs,
          children: [
            const SangaFieldLabel('Package value'),
            SangaMoneyField(
              controller: _value,
              hintText: '350,000',
              errorText: isTooHigh ? 'The most you can declare is ${SangaMoney.naira(catalog.maxDeclaredValue)}' : null,
              onChanged: _delivery.setDeclaredValue,
              onSubmitted: (_) {
                if (_isValid(catalog)) _next();
              },
            ),
          ],
        ),
        if (catalog.isHighValue(value))
          ValueWarning(
            title: 'High value item',
            message:
                'For items above ${SangaMoney.naira(catalog.highValueThreshold)} we recommend ${catalog.premiumTierLabel} '
                'for extra security and careful handling.',
          )
        else
          const SangaNotice(
            tone: SangaTone.neutral,
            icon: Icons.info_outline_rounded,
            message: 'Declaring a value is optional. It helps us handle your item with the right care, especially pricey ones.',
          ),
      ],
    );
  }
}
