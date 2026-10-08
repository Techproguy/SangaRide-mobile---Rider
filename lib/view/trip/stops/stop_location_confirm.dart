import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/widgets/map/place_marker.dart';
import 'package:sanga_ride/view/widgets/map/sanga_map.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class StopLocationConfirm extends StatefulWidget {
  const StopLocationConfirm({
    super.key,
    required this.place,
    required this.stopNumber,
    required this.onConfirm,
    required this.onChange,
    required this.onBack,
  });

  static const double _zoom = 16;

  final Place place;
  final int stopNumber;
  final VoidCallback onConfirm;
  final VoidCallback onChange;
  final VoidCallback onBack;

  @override
  State<StopLocationConfirm> createState() => _StopLocationConfirmState();
}

class _StopLocationConfirmState extends State<StopLocationConfirm> {
  Set<Marker> _markers = const {};

  LatLng get _position => widget.place.coordinates!;

  @override
  void initState() {
    super.initState();
    _drawMarker();
  }

  Future<void> _drawMarker() async {
    final marker = await PlaceMarker.marker(
      id: 'stop',
      kind: PlaceMarkerKind.stop,
      position: _position,
      title: widget.place.name,
      subtitle: 'Stop ${widget.stopNumber}',
    );
    if (mounted) setState(() => _markers = {marker});
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SangaSystemUi.onLight,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: SangaMap(
                followsUser: false,
                initialCameraPosition: CameraPosition(target: _position, zoom: StopLocationConfirm._zoom),
                extraMarkers: _markers,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(SangaSpacing.gutter, SangaSpacing.sm, SangaSpacing.gutter, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SangaMapButton.back(onPressed: widget.onBack),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SangaMapPanel(
                children: [
                  Text('Selected location', textAlign: TextAlign.center, style: SangaTextStyles.sheetTitle),
                  const SizedBox(height: SangaSpacing.md),
                  SangaLocationRow(
                    kind: SangaStopKind.stop,
                    title: widget.place.name,
                    subtitle: widget.place.address,
                    onTap: widget.onChange,
                    trailing: Text('Change', style: SangaTextStyles.link),
                  ),
                  const SizedBox(height: SangaSpacing.lg),
                  SangaButton.primary(label: 'Confirm this location', onPressed: widget.onConfirm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
