import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sanga_ride/controller/rider/rider_sign_up_controller.dart';
import 'package:sanga_ride/core/copy/common_copy.dart';
import 'package:sanga_ride/core/router/routes.dart';
import 'package:sanga_ride/core/services/location_service.dart';
import 'package:sanga_ride/core/services/places_service.dart';
import 'package:sanga_ride/core/services/permission_center.dart';
import 'package:sanga_ride/view/auth/widgets/sign_up_error_notice.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/auth/sign_up_steps.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class HomeLocationScreen extends StatefulWidget {
  const HomeLocationScreen({super.key});

  @override
  State<HomeLocationScreen> createState() => _HomeLocationScreenState();
}

class _HomeLocationScreenState extends State<HomeLocationScreen> {
  static const _debounce = Duration(milliseconds: 300);

  final _signUp = Get.find<RiderSignUpController>();
  final _permissions = Get.find<PermissionCenter>();
  final _places = PlacesService();
  final _location = LocationService();
  final _query = TextEditingController();
  Timer? _searchTimer;
  List<Place> _results = const [];
  Place? _home;
  var _isSearching = false;
  var _isLocating = false;

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

  void _choose(Place place) {
    FocusScope.of(context).unfocus();
    _query.text = place.address;
    setState(() {
      _home = place;
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
        title: 'Location access is off',
        message: 'Let Sanga Ride use your location in Settings, or search for your address instead.',
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
    if (place != null) return _choose(place);
    SangaToast.show(switch (result.status) {
      LocationStatus.serviceDisabled => 'Turn on location services to use where you are.',
      LocationStatus.denied || LocationStatus.deniedForever => 'Allow location access to use where you are.',
      _ => 'We couldn’t find where you are. Search for your address instead.',
    }, tone: SangaToastTone.error);
  }

  Future<void> _save() async {
    final home = _home;
    if (home == null || _signUp.isSaving) return;
    if (await _signUp.saveHome(home)) await _finish();
  }

  Future<void> _skip() async {
    _signUp.skipHome();
    await _finish();
  }

  Future<void> _finish() async {
    await showSangaStatusSheet(
      context: context,
      status: SangaStatus.success,
      title: 'You’re all set!',
      message: 'Welcome to Sanga Ride. Let’s get you moving.',
      actionLabel: 'Let’s go',
    );
    if (mounted) context.go(SangaRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final hasNoMatches = !_isSearching && _home == null && _query.text.trim().isNotEmpty && _results.isEmpty;
    return SangaFormLayout(
      title: 'Where’s home?',
      subtitle: 'Save it once and home is always one tap away',
      step: RiderSignUpStep.home.formStep,
      children: [
        SangaSearchField(
          controller: _query,
          hintText: 'Enter your address',
          onChanged: _onQueryChanged,
          onCleared: () => _onQueryChanged(''),
        ),
        const SizedBox(height: SangaSpacing.sm),
        SangaTonalButton(
          icon: SangaAssets.send,
          label: 'Use my current location',
          isLoading: _isLocating,
          onPressed: _useCurrentLocation,
        ),
        const SizedBox(height: SangaSpacing.md),
        for (final place in _results)
          SangaPlaceTile(title: place.name, subtitle: place.address, onTap: () => _choose(place)),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(SangaSpacing.md),
            child: Center(child: SangaActivityIndicator(size: 24, color: SangaColors.primary)),
          ),
        if (hasNoMatches)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SangaSpacing.md),
            child: Text(
              'No matches yet. Try a street, area or landmark.',
              textAlign: TextAlign.center,
              style: SangaTextStyles.body,
            ),
          ),
        const SizedBox(height: SangaSpacing.xxl),
        const SignUpErrorNotice(),
        Obx(
          () => SangaButton.primary(
            label: 'Continue',
            isLoading: _signUp.isSaving,
            onPressed: _home == null ? null : _save,
          ),
        ),
        const SizedBox(height: SangaSpacing.xs),
        Center(
          child: SangaTextAction(label: 'Skip for now', onPressed: _skip, isMuted: true),
        ),
      ],
    );
  }
}
