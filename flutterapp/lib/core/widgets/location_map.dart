import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../location/url_opener.dart';
import '../theme/app_theme.dart';

/// Phnom Penh - default map centre.
const phnomPenh = LatLng(11.5564, 104.9282);

/// OpenStreetMap tiles (no API key). Replaceable in tests.
final mapTileProviderProvider = Provider<TileProvider>(
  (ref) => NetworkTileProvider(),
);

Widget _tileLayer(WidgetRef ref) => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.ecom.ecom_mobile',
  tileProvider: ref.watch(mapTileProviderProvider),
);

/// Required by the OpenStreetMap tile usage policy.
class _OsmAttribution extends ConsumerWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context, WidgetRef ref) => RichAttributionWidget(
    alignment: AttributionAlignment.bottomLeft,
    popupInitialDisplayDuration: Duration.zero,
    attributions: [
      TextSourceAttribution(
        'OpenStreetMap contributors',
        onTap: () => ref.read(urlOpenerProvider)(
          Uri.parse('https://www.openstreetmap.org/copyright'),
        ),
      ),
    ],
  );
}

class _Pin extends StatelessWidget {
  const _Pin();
  @override
  Widget build(BuildContext context) => const Icon(
    Icons.location_on,
    size: 44,
    color: AppColors.danger,
    shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
  );
}

/// Interactive map: tap to place the pin, drag the pin (or pan/zoom the map).
class LocationPickerMap extends ConsumerStatefulWidget {
  const LocationPickerMap({
    super.key,
    required this.pin,
    required this.onPinChanged,
    required this.controller,
    this.accuracyMeters,
    this.height = 220,
  });

  final LatLng? pin;
  final ValueChanged<LatLng> onPinChanged;
  final MapController controller;

  /// Draws an accuracy circle (radius in metres) around the pin.
  final double? accuracyMeters;
  final double height;

  @override
  ConsumerState<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends ConsumerState<LocationPickerMap> {
  Offset? _dragStart; // screen position of the pin when the drag began
  Offset _dragDelta = Offset.zero;
  bool _draggingPin = false;

  void _endDrag() {
    _dragStart = null;
    if (mounted && _draggingPin) setState(() => _draggingPin = false);
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: widget.controller,
          options: MapOptions(
            initialCenter: pin ?? phnomPenh,
            initialZoom: pin == null ? 12 : 16,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: InteractionOptions(
              // Map stays put while the pin is being dragged.
              flags: _draggingPin
                  ? InteractiveFlag.none
                  // No double-tap zoom: it delays every tap (pin placement)
                  // by ~250 ms. Pinch / wheel zoom still work.
                  : InteractiveFlag.all &
                        ~InteractiveFlag.rotate &
                        ~InteractiveFlag.doubleTapZoom &
                        ~InteractiveFlag.doubleTapDragZoom,
            ),
            onTap: (_, point) => widget.onPinChanged(point),
          ),
          children: [
            _tileLayer(ref),
            if (pin != null && widget.accuracyMeters != null)
              CircleLayer(
                key: const Key('accuracy_circle'),
                circles: [
                  CircleMarker(
                    point: pin,
                    radius: widget.accuracyMeters!,
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderColor: Colors.blue.withValues(alpha: 0.7),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            if (pin != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: pin,
                    width: 48,
                    height: 48,
                    // The icon's tip sits on the coordinate.
                    alignment: Alignment.topCenter,
                    // Raw pointer events: unlike a GestureDetector they do not
                    // lose the gesture arena to the map's own pan/zoom.
                    child: Listener(
                      key: const Key('map_pin'),
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) {
                        _dragStart = widget.controller.camera
                            .latLngToScreenOffset(pin);
                        _dragDelta = Offset.zero;
                        setState(() => _draggingPin = true);
                      },
                      onPointerMove: (e) {
                        final start = _dragStart;
                        if (start == null) return;
                        _dragDelta += e.delta;
                        widget.onPinChanged(
                          widget.controller.camera.screenOffsetToLatLng(
                            start + _dragDelta,
                          ),
                        );
                      },
                      onPointerUp: (_) => _endDrag(),
                      onPointerCancel: (_) => _endDrag(),
                      child: const _Pin(),
                    ),
                  ),
                ],
              ),
            const _OsmAttribution(),
          ],
        ),
      ),
    );
  }
}

/// Small read-only map with the pin. Tap opens Google Maps.
class MapPreview extends ConsumerWidget {
  const MapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 120,
  });

  final double latitude;
  final double longitude;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final point = LatLng(latitude, longitude);
    return Semantics(
      button: true,
      label: 'Open in Google Maps',
      child: GestureDetector(
        key: const Key('map_preview'),
        behavior: HitTestBehavior.opaque,
        onTap: () => ref
            .read(urlOpenerProvider)(googleMapsUri(latitude, longitude))
            .then((ok) {
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open Google Maps')),
                );
              }
            }),
        child: SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Not interactive: taps go to the GestureDetector above.
                IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      _tileLayer(ref),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const _Pin(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 0,
                  bottom: 0,
                  child: _PreviewAttribution(),
                ),
                const Positioned(
                  right: 6,
                  top: 6,
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewAttribution extends StatelessWidget {
  const _PreviewAttribution();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    color: Colors.white70,
    child: const Text(
      '© OpenStreetMap contributors',
      style: TextStyle(fontSize: 9, color: Colors.black87),
    ),
  );
}

/// Moves/zooms [controller] so the whole accuracy circle around [center] is
/// visible (zooms out for coarse fixes, zooms in to 16 for accurate ones).
void showAccuracy(MapController controller, LatLng center, double? meters) {
  if (meters == null || meters <= 60) {
    controller.move(center, 16);
    return;
  }
  const d = Distance();
  controller.fitCamera(
    CameraFit.coordinates(
      coordinates: [
        d.offset(center, meters, 0),
        d.offset(center, meters, 90),
        d.offset(center, meters, 180),
        d.offset(center, meters, 270),
      ],
      padding: const EdgeInsets.all(24),
      maxZoom: 17,
    ),
  );
}
