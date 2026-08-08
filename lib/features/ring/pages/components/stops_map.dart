import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/providers/location_provider.dart';
import '../../models/ring_stop.dart';

/// Duraklarin haritasi. Konum izni yoksa kampus merkezine odaklanir ve mavi
/// nokta gosterilmez — sayfa yine calisir.
///
/// [ConsumerStatefulWidget] yalnizca [GoogleMapController]'i ve haritanin
/// hazir olma durumunu tutmak icin; arayuz state'i Riverpod'da kalir,
/// `setState` cagrilmaz. Gecici, tamamen widget'a ozgu iki bayrak icin
/// Riverpod'a global state eklemek yerine [ValueNotifier] kullanilir.
///
/// **Neden gecikmeli montaj:** `GoogleMap` bir platform view'dir; olusturulmasi
/// Maps SDK'sini surece yukler (GMS dynamite modulu, GL context, ilk tile'lar).
/// Bu is ilk kareyi blokladigi icin sayfa dogrudan monte edildiginde gecis
/// animasyonu ilerleyemiyor ve kullaniciya "buton tepki vermedi" gibi
/// goruluyordu. Bu yuzden harita **gecis animasyonu bittikten sonra** monte
/// edilir; o ana kadar ve harita hazir olana dek yer tutucu gosterilir.
class StopsMap extends ConsumerStatefulWidget {
  final List<RingStop> stops;
  final ValueChanged<String> onStopTap;

  const StopsMap({super.key, required this.stops, required this.onStopTap});

  @override
  ConsumerState<StopsMap> createState() => _StopsMapState();
}

class _StopsMapState extends ConsumerState<StopsMap> {
  static const _campusCenter = LatLng(36.8969, 30.6364);

  GoogleMapController? _controller;

  /// Platform view monte edilebilir mi — gecis animasyonu bitince `true`.
  final _canMount = ValueNotifier(false);

  /// Harita cizmeye hazir mi — [GoogleMap.onMapCreated] tetiklenince `true`.
  final _isReady = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mountWhenSettled());
  }

  /// Gecis animasyonu bitene kadar bekler. Route animasyonu yoksa (sekme
  /// degisimi, testler) hemen monte eder.
  void _mountWhenSettled() {
    if (!mounted) return;

    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _canMount.value = true;
      return;
    }

    void onStatus(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(onStatus);
      _canMount.value = true;
    }

    animation.addStatusListener(onStatus);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _canMount.dispose();
    _isReady.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(userPositionProvider);

    // Konum sonradan gelirse kamerayi kullaniciya tasi.
    ref.listen(userPositionProvider, (previous, next) {
      if (next == null || previous != null) return;
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(next.latitude, next.longitude), 15.5),
      );
    });

    final target = position == null
        ? _campusCenter
        : LatLng(position.latitude, position.longitude);

    return ValueListenableBuilder<bool>(
      valueListenable: _canMount,
      builder: (context, canMount, child) {
        if (!canMount) return const _MapPlaceholder();

        return Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 15),
              onMapCreated: (controller) {
                _controller = controller;
                _isReady.value = true;
              },
              markers: {
                for (final stop in widget.stops)
                  Marker(
                    markerId: MarkerId(stop.id),
                    position: LatLng(stop.lat, stop.lng),
                    infoWindow: InfoWindow(
                      title: stop.name,
                      onTap: () => widget.onStopTap(stop.id),
                    ),
                    onTap: () => widget.onStopTap(stop.id),
                  ),
              },
              myLocationEnabled: position != null,
              myLocationButtonEnabled: position != null,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            // Harita hazir olana dek ustte kalir; SDK yuklenirken altta
            // olusan bos/gri alan kullaniciya gosterilmez.
            ValueListenableBuilder<bool>(
              valueListenable: _isReady,
              builder: (context, isReady, child) => AnimatedOpacity(
                opacity: isReady ? 0 : 1,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: isReady,
                  child: const _MapPlaceholder(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Harita yuklenene kadar duran yer tutucu. Sayfanin geri kalani — durak
/// listesi, mesafeler — bu sirada tam calisir; bekleyen tek sey haritadir.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Harita yükleniyor',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
