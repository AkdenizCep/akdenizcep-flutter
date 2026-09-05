import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/providers/location_provider.dart';
import '../models/ring_stop.dart';
import '../models/route_shape.dart';
import '../providers/ring_provider.dart';
import 'components/open_stop_detail.dart';
import 'components/route_map_filters.dart';
import 'components/stop_map_card.dart';
import 'components/stops_map.dart';

/// Yakındaki duraklar: tam ekran harita + altta yatay kaydırmalı durak kartları.
///
/// Konum izni yoksa sayfa yine açılır — harita kampüse odaklanır, kartlar
/// güzergâh sırasına göre dizilir ve mesafeler gizlenir.
///
/// Yüzen alt nav bar görünür kalır; kart şeridi onun üstünde durur.
class RingStopsPage extends ConsumerStatefulWidget {
  final String? initialStopId;

  const RingStopsPage({super.key, this.initialStopId});

  @override
  ConsumerState<RingStopsPage> createState() => _RingStopsPageState();
}

class _RingStopsPageState extends ConsumerState<RingStopsPage> {
  /// Kart şeridi ile pinleri senkron tutar.
  PageController? _pageController;

  final _searchController = TextEditingController();

  /// Harita tipi yalnızca bu sayfayı ilgilendirir — global state'e taşınmaz.
  MapType _mapType = MapType.normal;

  /// [StopsMap]'e "kamerayı kullanıcıya döndür" demenin yolu.
  int _recenterTick = 0;

  /// Kamera hareketi secili durak state'inden ayridir. Yalnizca kullanicinin
  /// kart seridindeki acik secimi bu komutu uretir.
  String? _focusStopId;
  int _focusStopTick = 0;

  bool _autoSelectWhenEmpty = true;
  bool _suppressStripCameraFocus = false;

  bool _initialStopScheduled = false;
  bool _initialStopApplied = false;
  String? _syncedVisibleStopsKey;

  @override
  void didUpdateWidget(covariant RingStopsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStopId == widget.initialStopId) return;

    _initialStopScheduled = false;
    _initialStopApplied = false;
    _syncedVisibleStopsKey = null;
    _autoSelectWhenEmpty = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Kart genisligi (274) + aralik (12) ekranin oranina cevrilir; `padEnds`
    // kapali oldugu icin ilk kart sol kenardan 20 iceride baslar.
    final width = MediaQuery.of(context).size.width - 20;
    final fraction = (286 / width).clamp(0.1, 1.0);
    if (_pageController?.viewportFraction == fraction) return;

    _pageController?.dispose();
    _pageController = PageController(viewportFraction: fraction);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stops = ref.watch(visibleStopsProvider);
    final hasLocation = ref.watch(userPositionProvider) != null;
    final query = ref.watch(stopQueryProvider);

    // Veri henüz gelmediyse "durak girilmemiş" demek yanlış bilgi olur —
    // yükleme, boş ve hata durumları ayrı ayrı karşılanır.
    final stopsAsync = ref.watch(ringStopsProvider);
    final allStops = ref.watch(nearbyStopsProvider);

    final selectedId = ref.watch(selectedStopProvider);

    if (!_initialStopScheduled && widget.initialStopId != null) {
      final matches = allStops.where(
        (nearby) => nearby.stop.id == widget.initialStopId,
      );
      if (matches.isNotEmpty) {
        _initialStopScheduled = true;
        _selectInitialStopAfterFrame(matches.first);
      } else if (stopsAsync.hasValue) {
        // Elle yazilmis/gecersiz bir deep link sayfayi secimsiz birakmasin.
        _initialStopScheduled = true;
        _discardMissingInitialStopAfterFrame();
      }
    }

    // Şerit ilk dolduğunda — ve arama seçili durağı listeden düşürdüğünde —
    // ilk kart öne çıkar. Kart ile pin hiçbir zaman ayrı duraklarda kalmaz.
    if (stops.isNotEmpty &&
        (widget.initialStopId == null || _initialStopApplied) &&
        ((selectedId == null && _autoSelectWhenEmpty) ||
            (selectedId != null &&
                !stops.any((n) => n.stop.id == selectedId)))) {
      _autoSelectWhenEmpty = false;
      _selectFirstAfterFrame(stops.first.stop.id);
    }

    if (selectedId != null &&
        stops.any((nearby) => nearby.stop.id == selectedId)) {
      final visibleStopsKey = stops.map((nearby) => nearby.stop.id).join('|');
      if (_syncedVisibleStopsKey != visibleStopsKey) {
        _syncedVisibleStopsKey = visibleStopsKey;
        _syncStripAfterFrame(selectedId);
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: StopsMap(
              stops: stops.map((s) => s.stop).toList(),
              routes: ref.watch(visibleRouteShapesProvider),
              onRouteTap: _showRouteInfo,
              mapType: _mapType,
              recenterTick: _recenterTick,
              focusStopId: _focusStopId,
              focusTick: _focusStopTick,
              initialFocusStopId: widget.initialStopId,
              onStopTap: _selectFromMap,
            ),
          ),

          // Yüzen kontrollerin harita üzerinde okunabilir kalması için.
          const Positioned.fill(child: IgnorePointer(child: _MapScrim())),

          // Üst satır: geri + arama
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _RoundMapButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Geri',
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 10),
                Expanded(child: _MapSearchField(controller: _searchController)),
              ],
            ),
          ),

          // Sağ kenar: konum ve katman butonları
          Positioned(
            top: MediaQuery.of(context).padding.top + 68,
            right: 20,
            child: Column(
              children: [
                _SquareMapButton(
                  icon: hasLocation
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  tooltip: hasLocation ? 'Konumuma dön' : 'Konumunu aç',
                  isPrimary: true,
                  onTap: _recenter,
                ),
                const SizedBox(height: 8),
                _SquareMapButton(
                  icon: Icons.layers_rounded,
                  tooltip: 'Harita görünümü',
                  onTap: () => setState(() {
                    _mapType = _mapType == MapType.normal
                        ? MapType.hybrid
                        : MapType.normal;
                  }),
                ),
              ],
            ),
          ),

          // Sol ust: tek, kompakt hat + yon kontrolu.
          Positioned(
            top: MediaQuery.of(context).padding.top + 68,
            left: 20,
            child: RouteMapFilters(onFilterChanged: _onRouteFilterChanged),
          ),

          // Yükleme / hata / boş durumlar haritanın üstünde bir kart olarak.
          if (allStops.isEmpty)
            Center(
              child: switch (stopsAsync) {
                AsyncLoading() => const _MapMessageCard(
                  icon: null,
                  title: 'Duraklar yükleniyor',
                ),
                // Duraklar asset'ten okunuyor; buraya dusmek genelde
                // "asset paketlenmemis" demektir (yeni asset eklendikten
                // sonra hot reload yetmez, yeniden baslatmak gerekir).
                AsyncError(:final error) => _MapMessageCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'Durak bilgisi alınamadı.',
                  subtitle: kDebugMode
                      ? '$error'
                      : 'Uygulamayı yeniden başlatmayı dene.',
                ),
                _ => const _MapMessageCard(
                  icon: Icons.location_off_outlined,
                  title: 'Durak bilgisi henüz girilmemiş.',
                ),
              },
            )
          else if (stops.isEmpty)
            Center(
              child: _MapMessageCard(
                icon: Icons.search_off_rounded,
                title: '"$query" için durak yok.',
              ),
            ),

          // Alt: yatay kaydırmalı durak kartları
          if (stops.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              // Yuzen nav bar ekranin altindan 24 bosluk + 68 yukseklik
              // kapliyor; serit onun 12 ustunde durur.
              bottom: 104,
              child: _StopCardStrip(
                stops: stops,
                selectedId: selectedId,
                controller: _pageController!,
                onPageChanged: _selectFromStrip,
                onShowLines: (stopId) => openStopDetail(context, ref, stopId),
                onWalkingDirections: _openWalkingDirections,
              ),
            ),
        ],
      ),
    );
  }

  /// Seçim build sırasında yazılamaz (provider'ı build içinde değiştirmek
  /// hatadır), bu yüzden kare bitiminde uygulanır.
  void _selectFirstAfterFrame(String stopId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(selectedStopProvider) == stopId) return;
      ref.read(selectedStopProvider.notifier).state = stopId;
      _jumpStripWithoutCamera(0);
    });
  }

  void _selectInitialStopAfterFrame(NearbyStop nearby) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _initialStopApplied = true;
      _searchController.clear();
      ref.read(stopQueryProvider.notifier).state = '';
      if (nearby.stop.lineNames.isNotEmpty) {
        final activeLine = ref.read(activeRouteLineProvider);
        final activeDirection = ref.read(activeRouteDirectionProvider);
        final line = activeLine != null && nearby.stop.servesLine(activeLine)
            ? activeLine
            : nearby.stop.lineNames.first;
        ref.read(selectedRouteLineProvider.notifier).state = line;

        final services = nearby.stop.servedBy.where(
          (service) => service.shortName == line,
        );
        if (services.isNotEmpty) {
          ref.read(selectedRouteDirectionProvider.notifier).state =
              activeDirection != null &&
                  nearby.stop.servesRoute(line, activeDirection)
              ? activeDirection
              : services.first.directionId;
        }
      }
      ref.read(selectedStopProvider.notifier).state = nearby.stop.id;
    });
  }

  void _discardMissingInitialStopAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _initialStopApplied = true);
    });
  }

  void _syncStripAfterFrame(String stopId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(_pageController?.hasClients ?? false)) return;

      final index = ref
          .read(visibleStopsProvider)
          .indexWhere((nearby) => nearby.stop.id == stopId);
      if (index >= 0) _jumpStripWithoutCamera(index);
    });
  }

  /// Hat/yön değişimi seçili durağı ve kart şeridini sıfırlar; haritanın
  /// kamera konumuna dokunmaz. Kullanıcının kurduğu zoom ve kadraj korunur.
  void _onRouteFilterChanged() {
    ref.read(selectedStopProvider.notifier).state = null;
    _autoSelectWhenEmpty = false;
    _syncedVisibleStopsKey = null;
    _suppressStripCameraFocus = true;

    // Filtre state'i callback'ten hemen sonra degisir. Yeni liste cizildigi
    // karede seridi basa al; PageView'in programatik bildirimi kamerayi
    // hareket ettirmesin.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpStripWithoutCamera(0);
    });
  }

  void _selectFromStrip(int index) {
    final stops = ref.read(visibleStopsProvider);
    if (index < 0 || index >= stops.length) return;
    if (_suppressStripCameraFocus) return;

    final stopId = stops[index].stop.id;
    ref.read(selectedStopProvider.notifier).state = stopId;

    setState(() {
      _focusStopId = stopId;
      _focusStopTick++;
    });
  }

  void _jumpStripWithoutCamera(int index) {
    final controller = _pageController;
    _suppressStripCameraFocus = true;
    if (controller != null && controller.hasClients) {
      controller.jumpToPage(index);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressStripCameraFocus = false;
    });
  }

  /// Haritada bir pine dokunulduğunda ilgili kartı öne getirir.
  void _selectFromMap(String stopId) {
    ref.read(selectedStopProvider.notifier).state = stopId;

    final index = ref
        .read(visibleStopsProvider)
        .indexWhere((n) => n.stop.id == stopId);
    if (index < 0) return;

    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;

    _suppressStripCameraFocus = true;
    controller
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        )
        .whenComplete(() => _suppressStripCameraFocus = false);
  }

  /// Bir güzergâh çizgisine dokunulduğunda hangi hat olduğunu gösterir.
  void _showRouteInfo(RouteShape route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 104),
        content: Text(
          '${route.label} · ${route.lengthKm.toStringAsFixed(1)} km',
        ),
      ),
    );
  }

  Future<void> _recenter() async {
    if (ref.read(userPositionProvider) == null) {
      await _requestLocation(context);
      return;
    }
    setState(() => _recenterTick++);
  }

  Future<void> _openWalkingDirections(RingStop stop) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${stop.lat},${stop.lng}&travelmode=walking',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Harita uygulaması açılamadı.')),
    );
  }

  Future<void> _requestLocation(BuildContext context) async {
    final granted = await ref.read(userPositionProvider.notifier).request();
    if (granted || !context.mounted) return;

    final permanentlyDenied = await ref
        .read(userPositionProvider.notifier)
        .isPermanentlyDenied();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          permanentlyDenied
              ? 'Konum izni kapalı. Ayarlardan açabilirsin.'
              : 'Konum alınamadı. Konum servisin açık mı?',
        ),
        action: permanentlyDenied
            ? SnackBarAction(
                label: 'Ayarlar',
                onPressed: () =>
                    ref.read(userPositionProvider.notifier).openSettings(),
              )
            : null,
      ),
    );
  }
}

class _StopCardStrip extends StatelessWidget {
  final List<NearbyStop> stops;
  final String? selectedId;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onShowLines;
  final ValueChanged<RingStop> onWalkingDirections;

  const _StopCardStrip({
    required this.stops,
    required this.selectedId,
    required this.controller,
    required this.onPageChanged,
    required this.onShowLines,
    required this.onWalkingDirections,
  });

  @override
  Widget build(BuildContext context) {
    // Kart yuksekligi: 14 padding + 40 baslik + 10 + 24 rozet + 10 + 42 buton
    // + 14 padding = 154. Serit bundan buyuk olursa kartlar haritanin
    // ortasinda asili kalir.
    return SizedBox(
      height: 156,
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: PageView.builder(
          controller: controller,
          padEnds: false,
          onPageChanged: onPageChanged,
          itemCount: stops.length,
          itemBuilder: (context, index) {
            final nearby = stops[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Align(
                // Rozetsiz bir durak kisa kalabilir; artan bosluk kartin
                // ustunde birikmeli ki serit alt kenarda hizali dursun.
                alignment: Alignment.bottomLeft,
                child: StopMapCard(
                  nearby: nearby,
                  isSelected: nearby.stop.id == selectedId,
                  onShowLines: () => onShowLines(nearby.stop.id),
                  onWalkingDirections: () => onWalkingDirections(nearby.stop),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Üstte beyaza, altta koyuya çalan ince perde — beyaz butonlar ve beyaz
/// kartlar açık renkli harita karolarının üzerinde de seçilebilsin diye.
class _MapScrim extends StatelessWidget {
  const _MapScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.22, 0.6, 1],
          colors: [
            Colors.white.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.16),
          ],
        ),
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundMapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 23, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _SquareMapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isPrimary;
  final VoidCallback onTap;

  const _SquareMapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(15);

    return Material(
      color: colorScheme.surface,
      borderRadius: radius,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 21,
              color: isPrimary
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapSearchField extends ConsumerWidget {
  final TextEditingController controller;

  const _MapSearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(22);

    return Material(
      color: colorScheme.surface,
      borderRadius: radius,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: controller,
          onChanged: (value) =>
              ref.read(stopQueryProvider.notifier).state = value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Durak ara',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 15, right: 9),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Yükleme / hata / boş durumların haritanın üstündeki kart karşılığı.
class _MapMessageCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;

  const _MapMessageCard({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == null)
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: colorScheme.primary,
              ),
            )
          else
            Icon(icon, size: 44, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
