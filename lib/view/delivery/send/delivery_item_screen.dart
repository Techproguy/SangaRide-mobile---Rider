import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/core/router/delivery_routes.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/delivery/send/widgets/delivery_catalog_gate.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum _Field { name, description, size, packageType }

class DeliveryItemScreen extends StatefulWidget {
  const DeliveryItemScreen({super.key, required this.isEditing});

  final bool isEditing;

  @override
  State<DeliveryItemScreen> createState() => _DeliveryItemScreenState();
}

class _DeliveryItemScreenState extends State<DeliveryItemScreen> {
  final _delivery = Get.find<SendDeliveryController>();
  late final _name = TextEditingController(text: _delivery.draft.name);
  late final _description = TextEditingController(text: _delivery.draft.description);
  var _errors = <_Field, String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _delivery.loadCatalog());
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _clearError(_Field field) {
    if (_errors.containsKey(field)) setState(() => _errors = {..._errors}..remove(field));
  }

  Map<_Field, String> _validate() {
    final draft = _delivery.draft;
    final isDocuments = _delivery.isDocuments;
    return {
      if (draft.name.trim().isEmpty) _Field.name: 'Tell us what you’re sending',
      if (draft.description.trim().isEmpty) _Field.description: 'Add a few words about it',
      if (!isDocuments && draft.sizeId == null) _Field.size: 'Pick the closest size',
      if (!isDocuments && draft.packageTypeId == null) _Field.packageType: 'Tell us how careful we should be',
    };
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final errors = _validate();
    if (errors.isNotEmpty) return setState(() => _errors = errors);
    DeliveryRoutes.advance(context, next: DeliveryRoutes.photo, isEditing: widget.isEditing);
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: _delivery.isDocuments ? 'Document details' : 'Package details',
      subtitle: 'Tell us a bit about what you’re sending',
      footer: SangaButton.primary(label: widget.isEditing ? 'Save' : 'Continue', onPressed: _submit),
      children: [
        DeliveryCatalogGate(
          skeletonCount: 4,
          skeletonHeight: 56,
          builder: (context, catalog) => Obx(() => _form(catalog)),
        ),
      ],
    );
  }

  Widget _form(DeliveryCatalog catalog) {
    final draft = _delivery.draft;
    final isDocuments = _delivery.isDocuments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.lg,
      children: [
        SangaTextField(
          label: 'Item name',
          isRequired: true,
          hintText: isDocuments ? 'Contract, certificate, letter' : 'Birthday cake, phone, shoes',
          controller: _name,
          errorText: _errors[_Field.name],
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [LengthLimitingTextInputFormatter(DeliveryRules.itemNameMaxLength)],
          onChanged: (value) {
            _delivery.setName(value);
            _clearError(_Field.name);
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SangaTextArea(
              label: 'Description',
              controller: _description,
              hintText: 'What is it, and how should we handle it?',
              minLines: 3,
              maxLength: DeliveryRules.descriptionMaxLength,
              onChanged: (value) {
                _delivery.setDescription(value);
                _clearError(_Field.description);
              },
            ),
            SangaFieldError(_errors[_Field.description]),
          ],
        ),
        if (!isDocuments) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SangaSpacing.sm,
            children: [
              const SangaFieldLabel('Package size', isRequired: true),
              SangaChoiceChips<String>(
                options: [for (final size in catalog.sizes) SangaSelectOption(size.id, size.chipLabel)],
                value: draft.sizeId,
                onChanged: (id) {
                  _delivery.selectSize(id);
                  _clearError(_Field.size);
                },
              ),
              SangaFieldError(_errors[_Field.size]),
            ],
          ),
          SangaSelectField<String>(
            label: 'Package type',
            isRequired: true,
            hintText: 'Choose type',
            value: draft.packageTypeId,
            errorText: _errors[_Field.packageType],
            options: [for (final type in catalog.packageTypes) SangaSelectOption(type.id, type.label)],
            onChanged: (id) {
              _delivery.selectPackageType(id);
              _clearError(_Field.packageType);
            },
          ),
        ],
        SangaNotice(message: catalog.prohibitedNotice),
      ],
    );
  }
}
