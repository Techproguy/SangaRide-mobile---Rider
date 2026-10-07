import 'dart:developer';

import 'package:flutter/widgets.dart';

class SangaNavObserver extends NavigatorObserver {
  static const _tag = '[Nav]';

  String _name(Route<dynamic>? route) {
    if (route == null) return '?';
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    if (route is PopupRoute) return 'dialog:${route.runtimeType}';
    return route.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    log('$_tag push    ${_name(previousRoute)} -> ${_name(route)}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    log('$_tag pop     ${_name(route)} -> ${_name(previousRoute)}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    log('$_tag replace ${_name(oldRoute)} -> ${_name(newRoute)}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    log('$_tag remove  ${_name(route)} (back to ${_name(previousRoute)})');
  }
}
