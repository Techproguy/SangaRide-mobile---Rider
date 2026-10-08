import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/delivery/send_delivery_controller.dart';
import 'package:sanga_ride/core/router/delivery_routes.dart';
import 'package:sanga_ride/view/delivery/send/widgets/delivery_catalog_gate.dart';
import 'package:sanga_ride/view/delivery/send/widgets/delivery_hero.dart';
import 'package:sanga_ride/view/delivery/send/widgets/delivery_icons.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DeliveryKindScreen extends StatefulWidget {
  const DeliveryKindScreen({super.key});

  @override
  State<DeliveryKindScreen> createState() => _DeliveryKindScreenState();
}

class _DeliveryKindScreenState extends State<DeliveryKindScreen> {
  final _delivery = Get.find<SendDeliveryController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _delivery.loadCatalog());
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Send a package',
      footer: Obx(
        () => SangaButton.primary(
          label: 'Continue',
          onPressed: _delivery.kind == null ? null : () => context.push(DeliveryRoutes.item),
        ),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SangaSpacing.md,
          children: [
            const DeliveryHero(),
            const Text('What are you sending?', textAlign: TextAlign.center, style: SangaTextStyles.titleSmall),
            const Text(
              'Fast, careful deliveries across your city',
              textAlign: TextAlign.center,
              style: SangaTextStyles.body,
            ),
            const SizedBox(height: SangaSpacing.xs),
            DeliveryCatalogGate(
              builder: (context, catalog) => Obx(
                () => Column(
                  spacing: SangaSpacing.md,
                  children: [
                    for (final kind in catalog.kinds)
                      SangaOptionCard(
                        leading: SangaIconBadge(child: Icon(deliveryKindIcon(kind.id))),
                        title: kind.label,
                        subtitle: kind.hint,
                        isSelected: _delivery.draft.kindId == kind.id,
                        onTap: () => _delivery.selectKind(kind.id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
