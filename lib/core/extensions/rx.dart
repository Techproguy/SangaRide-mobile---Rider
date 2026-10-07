import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

extension RxWidgetExtension on Widget {
  Widget rx() => Obx(() => this);
}
