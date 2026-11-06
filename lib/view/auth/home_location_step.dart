import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/places_service.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/view/auth/widgets/sign_up_error_notice.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/auth/sign_up_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HomeLocationStep extends StatefulWidget {
  const HomeLocationStep({super.key, required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  State<HomeLocationStep> createState() => _HomeLocationStepState();
}

class _HomeLocationStepState extends State<HomeLocationStep> {
  static const _debounce = Duration(milliseconds: 300);

  final _signUp = Get.find<RiderSignUpController>();
  final _permissions = Get.find<PermissionCenter>();
  final _places = PlacesService();
  final _location = LocationService();
  final _query = TextEditingController();
  Timer? _searchTimer;
  List<Place> _results = const [];
  Place? _home;
  var _isHomeFromGps = false;
  var _isSearching = false;
  var _isLocating = false;
  var _isFinishing = false;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _searchTimer?.cancel();
    setState(() {
      _home = null;
      _isSearching = query.trim().isNotEmpty;
      if (!_isSearching) _results = const [];
    });
    if (_isSearching) _searchTimer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final results = await _places.searchPlaces(query);
    if (!mounted || query != _query.text) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  void _choose(Place place, {bool isFromGps = false}) {
    FocusScope.of(context).unfocus();
    _query.text = place.address;
    setState(() {
      _home = place;
      _isHomeFromGps = isFromGps;
      _results = const [];
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    final access = await _permissions.prime(PermissionKind.location, context);
    if (!mounted) return;
    if (access.needsSettings) {
      final openSettings = await showSangaPromptSheet(
        context: context,
        icon: Icons.location_disabled_rounded,
        title: SignUpCopy.locationOffTitle,
        message: SignUpCopy.locationOffMessage,
        actionLabel: CommonCopy.openSettings,
      );
      if (openSettings) await _permissions.openSettings();
      return;
    }
    if (!access.isUsable) return;
    setState(() => _isLocating = true);
    final result = await _location.resolveCurrentLocation(mayPrompt: true);
    final position = result.position;
    final place = position == null ? null : await _places.placeAt(position);
    if (!mounted) return;
    setState(() => _isLocating = false);
    if (place != null) return _choose(place, isFromGps: true);
    SangaToast.show(switch (result.status) {
      LocationStatus.serviceDisabled => SignUpCopy.turnOnLocationServices,
      LocationStatus.denied || LocationStatus.deniedForever => SignUpCopy.allowLocation,
      _ => SignUpCopy.locationNotFound,
    }, tone: SangaToastTone.error);
  }

  Future<void> _save() async {
    final home = _home;
    if (home == null || _signUp.isSaving) return;
    final isSaved = await _signUp.saveHome(home, isFromGps: _isHomeFromGps);
    if (isSaved && mounted) await _finish();
  }

  Future<void> _skip() async {
    _signUp.skipHome();
    await _finish();
  }

  Future<void> _finish() async {
    if (!mounted || _isFinishing) return;
    _isFinishing = true;
    try {
      await showSangaStatusSheet(
        context: context,
        status: SangaStatus.success,
        title: SignUpCopy.allSetTitle,
        message: SignUpCopy.allSetMessage,
        actionLabel: SignUpCopy.letsGo,
      );
      if (mounted) await widget.onFinished();
    } finally {
      _isFinishing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNoMatches = !_isSearching && _home == null && _query.text.trim().isNotEmpty && _results.isEmpty;
    return SangaStepPage(
      title: SignUpCopy.whereIsHome,
      subtitle: SignUpCopy.homeSubtitle,
      children: [
        SangaSearchField(
          controller: _query,
          hintText: SignUpCopy.enterYourAddress,
          onChanged: _onQueryChanged,
          onCleared: () => _onQueryChanged(''),
        ),
        const SizedBox(height: SangaSpacing.sm),
        SangaTonalButton(
          icon: SangaAssets.send,
          label: SignUpCopy.useMyCurrentLocation,
          isLoading: _isLocating,
          onPressed: _useCurrentLocation,
        ),
        const SizedBox(height: SangaSpacing.md),
        SangaReveal(
          isVisible: _results.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final place in _results)
                SangaPlaceTile(title: place.title, subtitle: place.subtitle, onTap: () => _choose(place)),
            ],
          ),
        ),
        SangaReveal(
          isVisible: _isSearching,
          child: const Padding(
            padding: EdgeInsets.all(SangaSpacing.md),
            child: Center(child: SangaActivityIndicator.content(size: 24, color: SangaColors.primary)),
          ),
        ),
        SangaReveal(
          isVisible: hasNoMatches,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SangaSpacing.md),
            child: Text(SignUpCopy.noMatches, textAlign: TextAlign.center, style: SangaTextStyles.body),
          ),
        ),
        const SignUpErrorNotice(),
        Obx(
          () => SangaButton.primary(
            label: SangaAuthCopy.continueLabel,
            isLoading: _signUp.isSaving,
            onPressed: _home == null ? null : _save,
          ),
        ),
        const SizedBox(height: SangaSpacing.xs),
        Center(
          child: SangaTextAction(label: SignUpCopy.skipForNow, onPressed: _skip, isMuted: true),
        ),
      ],
    );
  }
}
