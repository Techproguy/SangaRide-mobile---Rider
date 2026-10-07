import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanga_ride/core/services/toast_service.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/widgets/widgets.dart';

class HomeWidget extends StatefulWidget {
  final TabView? defaultTab;

  const HomeWidget({super.key, this.defaultTab});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  static const _tabs = TabView.values;
  final _navKey = GlobalKey<SangaNavigationState<TabView>>();
  DateTime? _lastBackAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: SangaNavigation<TabView>(key: _navKey, currentTab: widget.defaultTab ?? _tabs.first, tabs: _tabs),
      ),
    );
  }

  void _handleBack(bool didPop, Object? result) {
    if (didPop) return;
    final navState = _navKey.currentState;
    if (navState != null && navState.currentTabValue != _tabs.first) {
      navState.selectTab(_tabs.first);
      return;
    }
    final now = DateTime.now();
    if (_lastBackAt == null || now.difference(_lastBackAt!) > const Duration(seconds: 2)) {
      _lastBackAt = now;
      Toast.info('Press back again to exit');
      return;
    }
    SystemNavigator.pop();
  }
}
