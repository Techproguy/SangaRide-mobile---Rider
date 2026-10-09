import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/core/api/mock/mock_reset.dart';
import 'package:sanga_ride/core/router/router.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/session_restore.dart';
import 'package:sanga_ride/view/dev/dev_mock_switches.dart';
import 'package:sanga_ride/view/dev/dev_scenarios.dart';
import 'package:sanga_ride_core/mock.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class DevScreen extends StatelessWidget {
  const DevScreen({super.key});

  static const Duration _tokenLifetime = Duration(minutes: 2);
  static const Duration _clockSkew = Duration(minutes: 5);
  static const double _flakyRate = 0.2;

  NetworkLab get _lab => NetworkLab.instance;

  void _update(LabConditions Function(LabConditions current) change) {
    _lab.conditions.value = change(_lab.conditions.value);
  }

  void _resetAll() {
    _lab.reset();
    MockReset.clearRideActivity();
    SangaToast.show('Network and mock data reset', tone: SangaToastTone.success);
  }

  void _clearMockData() {
    MockReset.clearRideActivity();
    unawaited(Get.find<SessionRestore>().refreshQuietly());
    SangaToast.show('Mock data cleared', tone: SangaToastTone.success);
  }

  @override
  Widget build(BuildContext context) {
    return SangaPageLayout(
      title: 'Dev tools',
      children: [
        const SangaSectionHeader('Network'),
        const SizedBox(height: SangaSpacing.sm),
        ValueListenableBuilder<LabConditions>(
          valueListenable: _lab.conditions,
          builder: (context, conditions, _) => _NetworkLab(
            conditions: conditions,
            onChanged: _update,
            tokenLifetime: _tokenLifetime,
            clockSkew: _clockSkew,
            flakyRate: _flakyRate,
          ),
        ),
        const SizedBox(height: SangaSpacing.xl),
        const SangaSectionHeader('Reset'),
        const SizedBox(height: SangaSpacing.sm),
        SangaButton.outline(label: 'Reset all', onPressed: _resetAll),
        const SizedBox(height: SangaSpacing.sm),
        SangaButton.outline(label: 'Clear mock data', onPressed: _clearMockData),
        const SizedBox(height: SangaSpacing.sm),
        SangaButton.outline(label: 'Run startup again', onPressed: () => SangaRouter.router.go(SangaRoutes.boot)),
        const SizedBox(height: SangaSpacing.xl),
        const DevMockSwitches(),
        const SizedBox(height: SangaSpacing.xl),
        const SangaSectionHeader('Scenario hooks'),
        const SizedBox(height: SangaSpacing.sm),
        SangaListGroup(children: [for (final scenario in DevScenarios.all) _ScenarioRow(scenario: scenario)]),
      ],
    );
  }
}

class _NetworkLab extends StatelessWidget {
  const _NetworkLab({
    required this.conditions,
    required this.onChanged,
    required this.tokenLifetime,
    required this.clockSkew,
    required this.flakyRate,
  });

  final LabConditions conditions;
  final void Function(LabConditions Function(LabConditions current) change) onChanged;
  final Duration tokenLifetime;
  final Duration clockSkew;
  final double flakyRate;

  static const Map<MockLatency, String> _latencyLabels = {
    MockLatency.instant: 'Instant',
    MockLatency.normal: 'Normal',
    MockLatency.slow: 'Slow',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SangaChoiceChips<MockLatency>(
          options: [for (final entry in _latencyLabels.entries) SangaSelectOption(entry.key, entry.value)],
          value: conditions.latency,
          onChanged: (latency) => onChanged((current) => current.copyWith(latency: latency)),
        ),
        _toggle(
          icon: Icons.wifi_off_rounded,
          title: 'Offline',
          subtitle: 'Every request fails before it is sent',
          value: conditions.isOffline,
          change: (current, on) => current.copyWith(isOffline: on),
        ),
        _toggle(
          icon: Icons.network_check_rounded,
          title: 'Flaky',
          subtitle: '20% of requests fail before they are sent',
          value: conditions.flakyRate > 0,
          change: (current, on) => current.copyWith(flakyRate: on ? flakyRate : 0),
        ),
        _toggle(
          icon: Icons.cloud_off_rounded,
          title: 'Server down',
          subtitle: 'Every request, health check included, gets a 503',
          value: conditions.isServerDown,
          change: (current, on) => current.copyWith(isServerDown: on),
        ),
        _toggle(
          icon: Icons.mark_email_unread_outlined,
          title: 'Lose responses',
          subtitle: 'Writes happen, then the reply never arrives',
          value: conditions.losesResponses,
          change: (current, on) => current.copyWith(losesResponses: on),
        ),
        _toggle(
          icon: Icons.timer_outlined,
          title: 'Token lifetime 2 min',
          subtitle: 'Access tokens expire quickly so refresh runs',
          value: conditions.tokenLifetime != null,
          change: (current, on) => current.copyWith(tokenLifetime: () => on ? tokenLifetime : null),
        ),
        _toggle(
          icon: Icons.schedule_rounded,
          title: 'Clock skew +5 min',
          subtitle: 'Server time runs five minutes ahead',
          value: conditions.clockSkew != Duration.zero,
          change: (current, on) => current.copyWith(clockSkew: on ? clockSkew : Duration.zero),
        ),
      ],
    );
  }

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required LabConditions Function(LabConditions current, bool on) change,
  }) {
    return SangaToggleRow(
      leading: Icon(icon, size: 22, color: SangaColors.textPrimary),
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: (on) => onChanged((current) => change(current, on)),
    );
  }
}

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({required this.scenario});

  final DevScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SangaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: SangaSpacing.xxs,
        children: [
          Text(scenario.area, style: SangaTextStyles.caption),
          Text(scenario.trigger, style: SangaTextStyles.cardTitle),
          Text(scenario.effect, style: SangaTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}
