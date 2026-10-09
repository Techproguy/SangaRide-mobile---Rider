import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/ride_match_controller.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum ApprovalOutcome { carriedOn, cancelled }

Future<ApprovalOutcome?> showApprovalSheet(BuildContext context) {
  return showSangaSheet<ApprovalOutcome>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    padding: const EdgeInsets.fromLTRB(SangaSpacing.xl, SangaSpacing.xxl, SangaSpacing.xl, SangaSpacing.xl),
    builder: (context) => const PopScope(canPop: false, child: _ApprovalSheet()),
  );
}

class _ApprovalSheet extends StatefulWidget {
  const _ApprovalSheet();

  @override
  State<_ApprovalSheet> createState() => _ApprovalSheetState();
}

class _ApprovalSheetState extends State<_ApprovalSheet> {
  final _match = Get.find<RideMatchController>();
  late final Worker _worker;
  bool _isClosed = false;
  bool _isCancelling = false;

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

  void _onState(RideMatchState state) {
    if (!mounted || _isClosed) return;
    switch (state) {
      case MatchAwaitingApproval() || MatchStarting():
        break;
      case MatchCancelled():
        _close(ApprovalOutcome.cancelled);
      default:
        _close(ApprovalOutcome.carriedOn);
    }
  }

  void _close(ApprovalOutcome outcome) {
    if (_isClosed) return;
    _isClosed = true;
    Navigator.of(context).pop(outcome);
  }

  Future<void> _cancel() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    await _match.cancelRequest();
    if (mounted && !_isClosed) setState(() => _isCancelling = false);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isApproved = _match.state is MatchStarting;
      return SangaStatusContent(
        status: SangaStatus.pending,
        title: isApproved ? 'Approved' : 'Waiting for approval',
        message: isApproved
            ? 'You’re good to go. Sending your request now.'
            : 'An admin has to say yes before this ride goes out. We’ll carry on the moment they do.',
        secondary: isApproved
            ? null
            : SangaTextAction(label: 'Cancel request', onPressed: _isCancelling ? null : _cancel),
      );
    });
  }
}
