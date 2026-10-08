import 'package:flutter/material.dart';

IconData deliveryKindIcon(String id) => switch (id) {
  'documents' => Icons.description_outlined,
  _ => Icons.inventory_2_outlined,
};

IconData deliveryTierIcon(String id) => switch (id) {
  'express' => Icons.bolt_rounded,
  'priority' => Icons.diamond_outlined,
  'premium_care' => Icons.verified_user_outlined,
  _ => Icons.check_circle_outline_rounded,
};
