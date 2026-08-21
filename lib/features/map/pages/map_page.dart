import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/components/progress_snackbar.dart';
import '../../../shared/providers/nav_visibility_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../models/campus_location.dart';
import '../providers/map_provider.dart';
import 'components/location_details_sheet.dart';
import 'components/map_action_buttons.dart';
import 'components/map_category_style.dart';
import 'components/map_location_cluster.dart';
import 'components/map_search_panel.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  static const _akdenizCenter = LatLng(36.8969, 30.6512);
  static const _initialCameraPosition = CameraPosition(
    target: _akdenizCenter,
    zoom: 15.1,
  );
  static const _clusterZoomThreshold = 15.0;
  static const _labelZoomThreshold = 15.7;

  final _searchController = TextEditingController();
  final _compactMarkerIcons = <String, BitmapDescriptor>{};
  final _clusterMarkerIcons = <int, BitmapDescriptor>{};
  final _labelMarkerIcons = <String, BitmapDescriptor>{};
  final _pendingCompactMarkerIcons = <String>{};
  final _pendingClusterMarkerIcons = <int>{};
  final _pendingLabelMarkerIcons = <String>{};
  GoogleMapController? _mapController;
  double _currentZoom = _initialCameraPosition.zoom;
  CampusLocation? _selectedLocation;

  int get _zoomBucket => (_currentZoom * 4).floor();
  bool get _shouldCluster => _currentZoom < _clusterZoomThreshold;
  bool get _shouldShowLabels => _currentZoom >= _labelZoomThreshold;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(filteredCampusLocationsProvider);
    final query = ref.watch(mapSearchQueryProvider);
    final selectedCategory = ref.watch(selectedMapCategoryProvider);
    final myLocationEnabled = ref.watch(mapMyLocationEnabledProvider);

    return PopScope(
      canPop: _selectedLocation == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeLocationDetails();
      },
      child: Scaffold(
        body: locationsAsync.when(
          data: (locations) {
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  mapType: MapType.normal,
                  markers: _buildMarkers(context, locations),
                  onMapCreated: (controller) => _mapController = controller,
                  onCameraMove: _onCameraMove,
                  myLocationEnabled: myLocationEnabled,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  padding: EdgeInsets.only(
                    top: 190 + MediaQuery.of(context).padding.top,
                    bottom: 126 + MediaQuery.of(context).padding.bottom,
                    right: 12,
                  ),
                  onTap: (_) {
                    FocusScope.of(context).unfocus();
                    _closeLocationDetails();
                  },
                ),
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: PointerInterceptor(
                      child: MapSearchPanel(
                        controller: _searchController,
                        query: query,
                        selectedCategory: selectedCategory,
                        onQueryChanged: (value) {
                          ref.read(mapSearchQueryProvider.notifier).state =
                              value;
                        },
                        onCategoryChanged: (category) {
                          ref.read(selectedMapCategoryProvider.notifier).state =
                              category;
                        },
                        onClearQuery: () {
                          _searchController.clear();
                          ref.read(mapSearchQueryProvider.notifier).state = '';
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 112 + MediaQuery.of(context).padding.bottom,
                  child: PointerInterceptor(
                    child: MapActionButtons(
                      onMyLocation: () => _goToMyLocation(context),
                      onCenterCampus: _centerCampus,
                    ),
                  ),
                ),
                if (locations.isEmpty)
                  Positioned(
                    left: 16,
                    right: 82,
                    bottom: 32 + MediaQuery.of(context).padding.bottom,
                    child: PointerInterceptor(child: const _MapHint()),
                  ),
                if (_selectedLocation case final location?)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LocationDetailsSheet(
                      location: location,
                      onClose: _closeLocationDetails,
                      onShowOnMap: () {
                        _closeLocationDetails();
                        _focusLocation(location, zoom: 17.2);
                      },
                      onGetDirections: () {
                        _closeLocationDetails();
                        _openDirections(context, location);
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () => const LoadingOverlay(),
          error: (e, _) => ErrorView(message: errorMessage(e)),
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(
    BuildContext context,
    List<CampusLocation> locations,
  ) {
    final showLabels = _shouldShowLabels;
    final brightness = Theme.of(context).brightness;
    final markers = <Marker>{};
    final groups = _shouldCluster
        ? clusterMapLocations(locations, zoom: _currentZoom)
        : locations
              .map(
                (location) => MapLocationCluster(
                  locations: [location],
                  latitude: location.latitude,
                  longitude: location.longitude,
                ),
              )
              .toList();

    for (final group in groups) {
      if (group.isCluster) {
        final count = group.locations.length;
        _ensureClusterMarkerIcon(count);
        final icon = _clusterMarkerIcons[count];
        if (icon == null) continue;

        markers.add(
          Marker(
            markerId: MarkerId('cluster_${group.id}'),
            position: LatLng(group.latitude, group.longitude),
            icon: icon,
            anchor: const Offset(0.5, 1),
            consumeTapEvents: true,
            zIndexInt: 1,
            onTap: () => _openCluster(group),
          ),
        );
        continue;
      }

      if (_shouldCluster) continue;

      final location = group.locations.single;
      final categoryColor = location.category.color(
        Theme.of(context).colorScheme,
      );
      final compactIconKey = _compactIconKey(location, brightness);
      final labelIconKey = _labelIconKey(location, brightness);
      _ensureCompactMarkerIcon(key: compactIconKey, color: categoryColor);
      final icon = showLabels
          ? _labelMarkerIcons[labelIconKey] ??
                _compactMarkerIcons[compactIconKey]
          : _compactMarkerIcons[compactIconKey];

      if (showLabels && !_labelMarkerIcons.containsKey(labelIconKey)) {
        _ensureLabelMarkerIcon(
          location: location,
          color: categoryColor,
          brightness: brightness,
        );
      }
      if (icon == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.latitude, location.longitude),
          icon: icon,
          anchor: const Offset(0.5, 1),
          consumeTapEvents: true,
          onTap: () => _openLocationDetails(location),
        ),
      );
    }

    return markers;
  }

  Future<void> _openLocationDetails(CampusLocation location) async {
    FocusScope.of(context).unfocus();
    await _focusLocation(
      location,
      zoom: _currentZoom < 16 ? 16.4 : _currentZoom,
    );
    if (!mounted) return;

    ref.read(selectedCampusLocationProvider.notifier).state = location;
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    setState(() => _selectedLocation = location);
  }

  void _closeLocationDetails() {
    if (_selectedLocation == null) return;

    setState(() => _selectedLocation = null);
    ref.read(selectedCampusLocationProvider.notifier).state = null;
    ref.read(bottomNavVisibleProvider.notifier).state = true;
  }

  void _onCameraMove(CameraPosition position) {
    final previousZoomBucket = _zoomBucket;
    final wasClustering = _shouldCluster;
    final wasShowingLabels = _shouldShowLabels;
    _currentZoom = position.zoom;
    final isClustering = _shouldCluster;
    final isShowingLabels = _shouldShowLabels;

    if ((wasClustering != isClustering ||
            wasShowingLabels != isShowingLabels ||
            (isClustering && previousZoomBucket != _zoomBucket)) &&
        mounted) {
      setState(() {});
    }
  }

  Future<void> _openCluster(MapLocationCluster cluster) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(cluster.latitude, cluster.longitude),
          zoom: (_currentZoom + 1.4).clamp(
            _currentZoom,
            _clusterZoomThreshold + 0.2,
          ),
        ),
      ),
    );
  }

  String _labelIconKey(CampusLocation location, Brightness brightness) {
    return '${location.id}_${brightness.name}';
  }

  String _compactIconKey(CampusLocation location, Brightness brightness) {
    return '${location.category.id}_${brightness.name}';
  }

  void _ensureCompactMarkerIcon({required String key, required Color color}) {
    if (_compactMarkerIcons.containsKey(key) ||
        _pendingCompactMarkerIcons.contains(key)) {
      return;
    }
    _pendingCompactMarkerIcons.add(key);

    _createCompactMarkerIcon(color: color).then((icon) {
      if (!mounted) return;
      setState(() {
        _compactMarkerIcons[key] = icon;
        _pendingCompactMarkerIcons.remove(key);
      });
    });
  }

  Future<BitmapDescriptor> _createCompactMarkerIcon({
    required Color color,
  }) async {
    const pixelRatio = 3.0;
    const logicalSize = 36.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.location_on_rounded.codePoint),
        style: TextStyle(
          color: color,
          fontSize: 34,
          fontFamily: Icons.location_on_rounded.fontFamily,
          package: Icons.location_on_rounded.fontPackage,
          shadows: const [
            Shadow(
              color: Color(0x45000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        (logicalSize - iconPainter.width) / 2,
        (logicalSize - iconPainter.height) / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      (logicalSize * pixelRatio).round(),
      (logicalSize * pixelRatio).round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  void _ensureClusterMarkerIcon(int count) {
    if (_clusterMarkerIcons.containsKey(count) ||
        _pendingClusterMarkerIcons.contains(count)) {
      return;
    }
    _pendingClusterMarkerIcons.add(count);

    _createClusterMarkerIcon(count).then((icon) {
      if (!mounted) return;
      setState(() {
        _clusterMarkerIcons[count] = icon;
        _pendingClusterMarkerIcons.remove(count);
      });
    });
  }

  Future<BitmapDescriptor> _createClusterMarkerIcon(int count) async {
    const pixelRatio = 3.0;
    const logicalSize = 42.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    final pinPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.location_on_rounded.codePoint),
        style: TextStyle(
          color: const Color(0xFFE53935),
          fontSize: 42,
          fontFamily: Icons.location_on_rounded.fontFamily,
          package: Icons.location_on_rounded.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pinPainter.paint(
      canvas,
      Offset(
        (logicalSize - pinPainter.width) / 2,
        (logicalSize - pinPainter.height) / 2,
      ),
    );

    canvas.drawCircle(
      const Offset(logicalSize / 2, 15.5),
      8.5,
      Paint()..color = const Color(0xFFE53935),
    );

    final countPainter = TextPainter(
      text: TextSpan(
        text: count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    countPainter.paint(
      canvas,
      Offset(
        (logicalSize - countPainter.width) / 2,
        15.5 - countPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      (logicalSize * pixelRatio).round(),
      (logicalSize * pixelRatio).round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
  }

  void _ensureLabelMarkerIcon({
    required CampusLocation location,
    required Color color,
    required Brightness brightness,
  }) {
    final key = _labelIconKey(location, brightness);
    if (_pendingLabelMarkerIcons.contains(key)) return;
    _pendingLabelMarkerIcons.add(key);

    _createLabelMarkerIcon(
      label: location.name,
      color: color,
      brightness: brightness,
    ).then((icon) {
      if (!mounted) return;
      setState(() {
        _labelMarkerIcons[key] = icon;
        _pendingLabelMarkerIcons.remove(key);
      });
    });
  }

  Future<BitmapDescriptor> _createLabelMarkerIcon({
    required String label,
    required Color color,
    required Brightness brightness,
  }) async {
    const pixelRatio = 2.0;
    const horizontalPadding = 14.0;
    const bubbleHeight = 38.0;
    const pointerHeight = 10.0;
    const dotRadius = 5.0;
    const maxTextWidth = 150.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      maxLines: 1,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxTextWidth);

    final logicalWidth = (textPainter.width + horizontalPadding * 2).clamp(
      72.0,
      maxTextWidth + horizontalPadding * 2,
    );
    const logicalHeight = bubbleHeight + pointerHeight + dotRadius * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, logicalWidth, bubbleHeight),
      const Radius.circular(18),
    );
    canvas.drawRRect(bubbleRect.shift(const Offset(0, 2)), shadowPaint);

    final bubblePaint = Paint()..color = color;
    canvas.drawRRect(bubbleRect, bubblePaint);

    final pointerPath = Path()
      ..moveTo(logicalWidth / 2 - 8, bubbleHeight - 1)
      ..lineTo(logicalWidth / 2 + 8, bubbleHeight - 1)
      ..lineTo(logicalWidth / 2, bubbleHeight + pointerHeight)
      ..close();
    canvas.drawPath(pointerPath, bubblePaint);

    final borderPaint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(bubbleRect.deflate(0.5), borderPaint);

    textPainter.paint(
      canvas,
      Offset(
        (logicalWidth - textPainter.width) / 2,
        (bubbleHeight - textPainter.height) / 2 + 1,
      ),
    );

    final dotCenter = Offset(
      logicalWidth / 2,
      bubbleHeight + pointerHeight + dotRadius,
    );
    canvas.drawCircle(
      dotCenter,
      dotRadius + 3,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawCircle(dotCenter, dotRadius, Paint()..color = color);

    final image = await recorder.endRecording().toImage(
      (logicalWidth * pixelRatio).round(),
      (logicalHeight * pixelRatio).round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes, imagePixelRatio: pixelRatio);
  }

  Future<void> _openDirections(
    BuildContext context,
    CampusLocation location,
  ) async {
    final url = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${location.latitude},${location.longitude}',
      'travelmode': 'walking',
    });

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (launched || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }

    if (context.mounted) {
      showProgressSnackBar(
        context,
        message: 'Yol tarifi açılamadı.',
        icon: Icons.info_rounded,
        accentColor: Theme.of(context).colorScheme.secondary,
      );
    }
  }

  Future<void> _goToMyLocation(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        showProgressSnackBar(
          context,
          message: 'Konum servisleri kapalı görünüyor.',
          icon: Icons.location_off_rounded,
          accentColor: Theme.of(context).colorScheme.secondary,
        );
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        showProgressSnackBar(
          context,
          message: 'Konum izni verilmedi. Haritayı yine kullanabilirsin.',
          icon: Icons.location_off_rounded,
          accentColor: Theme.of(context).colorScheme.secondary,
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      ref.read(mapMyLocationEnabledProvider.notifier).state = true;
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17,
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        showProgressSnackBar(
          context,
          message: 'Konum alınamadı. Biraz sonra tekrar deneyebilirsin.',
          icon: Icons.location_searching_rounded,
          accentColor: Theme.of(context).colorScheme.secondary,
        );
      }
    }
  }

  Future<void> _focusLocation(CampusLocation location, {double zoom = 17}) {
    return _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(location.latitude, location.longitude),
              zoom: zoom,
            ),
          ),
        ) ??
        Future.value();
  }

  Future<void> _centerCampus() {
    FocusScope.of(context).unfocus();
    return _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        ) ??
        Future.value();
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu filtreyle konum bulunamadı',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
