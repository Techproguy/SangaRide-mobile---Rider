import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/ride/matching/widgets/searching_sheet_content.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum SearchOutcome { seeDrivers, noDriver, failed, cancelled }

Future<SearchOutcome?> showSearchingSheet(BuildContext context) {
  return showSangaSheet<SearchOutcome>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.xl, SangaSpacing.xxl, SangaSpacing.xl, SangaSpacing.xl),
    builder: (context) => const PopScope(canPop: false, child: _SearchingSheet()),
  );
}

typedef _Progress = ({List<String> steps, int doneCount, DateTime? continueAt});

class _SearchingSheet extends StatefulWidget {
  const _SearchingSheet();

  @override
  State<_SearchingSheet> createState() => _SearchingSheetState();
}

class _SearchingSheetState extends State<_SearchingSheet> {
  final _match = Get.find<RideMatchController>();
  late _Progress _progress = _progressOf(_match.state) ?? (steps: const [], doneCount: 0, continueAt: null);
  late final Worker _worker;
  bool _isCancelling = false;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    _worker = ever(_match.stateRx, _onState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onState(_match.state));
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  _Progress? _progressOf(RideMatchState state) => switch (state) {
    MatchSearching(:final request) => (steps: request.stepLabels, doneCount: request.stepsDone, continueAt: null),
    MatchOffersReady(:final request, :final continueAt) => (
      steps: request.stepLabels,
      doneCount: request.stepsDone,
      continueAt: continueAt,
    ),
    _ => null,
  };

  void _onState(RideMatchState state) {
    if (!mounted) return;
    switch (state) {
      case MatchNoDriver():
        _close(SearchOutcome.noDriver);
      case MatchFailed():
        _close(SearchOutcome.failed);
      case MatchCancelled():
        _close(SearchOutcome.cancelled);
      default:
        final progress = _progressOf(state);
        if (progress != null) setState(() => _progress = progress);
    }
  }

  void _close(SearchOutcome outcome) {
    if (_isClosed) return;
    _isClosed = true;
    Navigator.of(context).pop(outcome);
  }

  Future<void> _cancel() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    final cancelled = await _match.cancelRequest();
    if (mounted && !cancelled) setState(() => _isCancelling = false);
  }

  @override
  Widget build(BuildContext context) {
    return SearchingSheetContent(
      steps: _progress.steps,
      doneCount: _progress.doneCount,
      continueAt: _progress.continueAt,
      isCancelling: _isCancelling,
      onCancel: _cancel,
      onContinue: () => _close(SearchOutcome.seeDrivers),
    );
  }
}
