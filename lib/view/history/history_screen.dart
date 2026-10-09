import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/scheduled_rides_controller.dart';
import 'package:sanga_ride/model/history/history_tab.dart';
import 'package:sanga_ride/view/history/widgets/history_feed.dart';
import 'package:sanga_ride/view/history/widgets/history_tab_bar.dart';
import 'package:sanga_ride/view/rides/widgets/scheduled_rides_body.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.initialTab = HistoryTab.completed});

  final HistoryTab initialTab;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: HistoryTab.values.length,
    vsync: this,
    initialIndex: widget.initialTab.index,
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Widget _body(HistoryTab tab) {
    final status = tab.status;
    if (status != null) return HistoryFeed(status: status);
    return const _ScheduledTab();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SangaPageHeader(title: 'Rides'),
              const SizedBox(height: SangaSpacing.sm),
              HistoryTabBar(controller: _tabs, labels: [for (final tab in HistoryTab.values) tab.label]),
              Expanded(
                child: ListenableBuilder(
                  listenable: _tabs,
                  builder: (context, _) {
                    final tab = HistoryTab.values[_tabs.index];
                    return SangaHandoff(value: tab, child: _body(tab));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledTab extends StatelessWidget {
  const _ScheduledTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: SangaColors.primary,
      onRefresh: () => Get.find<ScheduledRidesController>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          SangaSpacing.gutter,
          SangaSpacing.md,
          SangaSpacing.gutter,
          SangaSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: const [ScheduledRidesBody()],
      ),
    );
  }
}
