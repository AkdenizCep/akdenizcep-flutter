import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/providers/location_provider.dart';
import '../../models/ring_stop.dart';
import '../../models/route_shape.dart';
import '../../providers/ring_provider.dart';
import 'route_map_animation_plan.dart';

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

  /// Katman butonuyla degisen harita tipi.
  final MapType mapType;

  /// Haritada cizilecek hat guzergahlari. Bos liste = cizgi yok.
  final List<RouteShape> routes;

  /// Bir guzergah cizgisine dokunuldugunda.
  final ValueChanged<RouteShape>? onRouteTap;

  /// Her artisinda kamera kullanicinin konumuna doner. Sayac, "ayni komutu
  /// tekrar ver" diyebilmek icin — konum degismedigi halde butona basildiginda
  /// da kamera geri gelmelidir.
  final int recenterTick;

  /// Kart seridinde kullanicinin sectigi duraga kamerayi tasir. Kimlik ayni
  /// kalsa bile [focusTick] artirilabildigi icin komut tekrar calisabilir.
  final String? focusStopId;
  final int focusTick;

  /// Detay yapragindan gelindiginde ilk kamera hedefi kullanici konumu degil,
  /// kullanicinin zaten sectigi durak olur.
  final String? initialFocusStopId;

  const StopsMap({
    super.key,
    required this.stops,
    required this.onStopTap,
    this.routes = const [],
    this.onRouteTap,
    this.mapType = MapType.normal,
    this.recenterTick = 0,
    this.focusStopId,
    this.focusTick = 0,
    this.initialFocusStopId,
  });

  @override
  ConsumerState<StopsMap> createState() => _StopsMapState();
}

class _StopsMapState extends ConsumerState<StopsMap>
    with SingleTickerProviderStateMixin {
  static const _campusCenter = LatLng(36.8969, 30.6364);

  /// Durak pini. Maps'in damla bicimli varsayilan pini yerine otobus
  /// simgesi tasiyan bu gorsel kullanilir: haritada durak ile baska bir
  /// isaret bakisla ayrilir.
  static const _pinAsset = 'assets/images/ring_stop_pin.png';

  /// Mantiksal piksel genisligi; yukseklik gorselin en-boy oraniyla turetilir.
  /// Secili durak sadece **daha buyuk** cizilir — kart seridiyle hangi pinin
  /// eslestigi yine bakisla anlasilir.
  static const _pinWidth = 34.0;
  static const _selectedPinWidth = 46.0;

  GoogleMapController? _controller;

  /// Platform view monte edilebilir mi — gecis animasyonu bitince `true`.
  final _canMount = ValueNotifier(false);

  /// Harita cizmeye hazir mi — [GoogleMap.onMapCreated] tetiklenince `true`.
  final _isReady = ValueNotifier(false);

  /// Cozulmus pin gorselleri. Asset asenkron yuklendigi icin hazir olana dek
  /// `null` kalir ve Maps'in varsayilan pini kullanilir — duraklar bir kare
  /// bile kaybolmaz.
  final _pins = ValueNotifier<_StopPins?>(null);

  /// Native harita katmanina gonderilen animasyon kareleri 36 adimla
  /// sinirlidir. Bu, cizgiyi akici tutarken her ekran yenilemesinde platform
  /// kanalindan yeni bir polyline koleksiyonu gecilmesini onler.
  final _routeProgress = ValueNotifier(1.0);
  late final AnimationController _routeAnimationController;
  RouteMapAnimationPlan? _routeAnimationPlan;
  int _lastAnimationStep = -1;

  bool _pinsRequested = false;
  bool _initialFocusApplied = false;

  @override
  void initState() {
    super.initState();
    _routeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..addListener(_updateRouteAnimationFrame);
    _refreshRouteAnimationPlan();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mountWhenSettled());
  }

  void _updateRouteAnimationFrame() {
    const frameCount = 36;
    final eased = Curves.easeInOutCubic.transform(
      _routeAnimationController.value,
    );
    final step = (eased * frameCount).round().clamp(0, frameCount);
    if (step == _lastAnimationStep) return;

    _lastAnimationStep = step;
    _routeProgress.value = step / frameCount;
  }

  void _refreshRouteAnimationPlan() {
    _routeAnimationPlan = widget.routes.isEmpty
        ? null
        : RouteMapAnimationPlan(
            route: widget.routes.first,
            stops: widget.stops,
          );
  }

  void _startRouteAnimation() {
    _routeAnimationController.stop();
    _lastAnimationStep = -1;

    // Sistem animasyonlari kapatildiysa bilgi geciktirilmeden tam rota
    // gosterilir. Kamera her iki durumda da oldugu yerde kalir.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _routeProgress.value = 1;
      return;
    }

    _routeProgress.value = 0;
    _routeAnimationController.forward(from: 0);
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

  /// Gorseli cihazin piksel oranina gore cozmek icin [BuildContext] gerekir;
  /// bu yuzden [initState] degil burasi. Bir kez calisir.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPins();
  }

  Future<void> _loadPins() async {
    if (_pinsRequested) return;
    _pinsRequested = true;

    final configuration = createLocalImageConfiguration(context);
    final normal = await BitmapDescriptor.asset(
      configuration,
      _pinAsset,
      width: _pinWidth,
    );
    final selected = await BitmapDescriptor.asset(
      configuration,
      _pinAsset,
      width: _selectedPinWidth,
    );

    if (!mounted) return;
    _pins.value = _StopPins(normal: normal, selected: selected);
  }

  @override
  void didUpdateWidget(StopsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeChanged =
        _routeSignature(oldWidget.routes) != _routeSignature(widget.routes);
    final stopsChanged =
        _stopSignature(oldWidget.stops) != _stopSignature(widget.stops);
    if (routeChanged || stopsChanged) _refreshRouteAnimationPlan();
    if (routeChanged && widget.routes.isNotEmpty) _startRouteAnimation();

    if (widget.recenterTick != oldWidget.recenterTick) _recenterOnUser();
    if (widget.focusTick != oldWidget.focusTick && widget.focusStopId != null) {
      _panToStop(widget.focusStopId!);
    }

    if (oldWidget.initialFocusStopId != widget.initialFocusStopId) {
      _initialFocusApplied = false;
    }
    final initialFocusId = widget.initialFocusStopId;
    if (!_initialFocusApplied &&
        initialFocusId != null &&
        _containsStop(widget.stops, initialFocusId)) {
      _initialFocusApplied = _focusStop(initialFocusId);
    }
  }

  String _routeSignature(List<RouteShape> routes) =>
      routes.map((route) => route.id).join('|');

  String _stopSignature(List<RingStop> stops) {
    final ids = stops.map((stop) => stop.id).toList()..sort();
    return ids.join('|');
  }

  void _recenterOnUser() {
    final position = ref.read(userPositionProvider);
    if (position == null) return;
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        15.5,
      ),
    );
  }

  bool _containsStop(List<RingStop> stops, String stopId) =>
      stops.any((stop) => stop.id == stopId);

  bool _focusStop(String stopId) {
    final matches = widget.stops.where((stop) => stop.id == stopId);
    final controller = _controller;
    if (matches.isEmpty || controller == null) return false;

    final stop = matches.first;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(stop.lat, stop.lng), 16.5),
    );
    return true;
  }

  void _panToStop(String stopId) {
    final matches = widget.stops.where((stop) => stop.id == stopId);
    if (matches.isEmpty) return;

    final stop = matches.first;
    // Kart secimi mevcut zoom seviyesini korur; kullanicinin harita kadraji
    // yalnizca gerekli oldugu kadar yatay/dikey tasinir.
    _controller?.animateCamera(
      CameraUpdate.newLatLng(LatLng(stop.lat, stop.lng)),
    );
  }

  /// Konum bilinmiyorsa kamerayi guzergahlarin tamamina sigdirir — kampus
  /// disindan acildiginda kullanici cizgileri aramak zorunda kalmasin.
  ///
  /// Harita boyutu ilk kare cizilmeden bilinmedigi icin `newLatLngBounds`
  /// exception atabilir; bu yuzden kare bitiminde cagrilir.
  void _fitToRoutes() {
    if (widget.routes.isEmpty) return;
    if (ref.read(userPositionProvider) != null) return;

    final bounds = _unionBounds(widget.routes);
    if (bounds == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40));
    });
  }

  static LatLngBounds? _unionBounds(List<RouteShape> routes) {
    if (routes.isEmpty) return null;

    var south = routes.first.bounds.south;
    var west = routes.first.bounds.west;
    var north = routes.first.bounds.north;
    var east = routes.first.bounds.east;

    for (final route in routes.skip(1)) {
      south = south < route.bounds.south ? south : route.bounds.south;
      west = west < route.bounds.west ? west : route.bounds.west;
      north = north > route.bounds.north ? north : route.bounds.north;
      east = east > route.bounds.east ? east : route.bounds.east;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  /// "#RRGGBB" -> [Color]. Bicim bozuksa temanin birincil rengine duser.
  Color _routeColor(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (value == null) return Theme.of(context).colorScheme.primary;
    return Color(0xFF000000 | value);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _routeAnimationController.dispose();
    _canMount.dispose();
    _isReady.dispose();
    _pins.dispose();
    _routeProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(userPositionProvider);
    final selectedId = ref.watch(selectedStopProvider);

    // Konum sonradan gelirse kamerayi kullaniciya tasi.
    ref.listen(userPositionProvider, (previous, next) {
      if (next == null || previous != null) return;
      if (widget.initialFocusStopId != null) return;
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(next.latitude, next.longitude), 15.5),
      );
    });

    final initialMatches = widget.stops.where(
      (stop) => stop.id == widget.initialFocusStopId,
    );
    final initialStop = initialMatches.isEmpty ? null : initialMatches.first;
    final target = initialStop != null
        ? LatLng(initialStop.lat, initialStop.lng)
        : position == null
        ? _campusCenter
        : LatLng(position.latitude, position.longitude);

    return ValueListenableBuilder<bool>(
      valueListenable: _canMount,
      builder: (context, canMount, child) {
        if (!canMount) return const _MapPlaceholder();

        return Stack(
          fit: StackFit.expand,
          children: [
            ValueListenableBuilder<_StopPins?>(
              valueListenable: _pins,
              builder: (context, pins, child) => ValueListenableBuilder<double>(
                valueListenable: _routeProgress,
                builder: (context, routeProgress, child) {
                  final plan = _routeAnimationPlan;
                  final animatingRoute = plan != null && routeProgress < 1;
                  final visibleStopIds = animatingRoute
                      ? plan.visibleStopIdsAt(routeProgress)
                      : const <String>{};

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: target,
                      zoom: 15,
                    ),
                    mapType: widget.mapType,
                    onMapCreated: (controller) {
                      _controller = controller;
                      _isReady.value = true;
                      final focusId = widget.initialFocusStopId;
                      if (focusId != null && _focusStop(focusId)) {
                        _initialFocusApplied = true;
                      } else {
                        _fitToRoutes();
                      }
                    },
                    markers: {
                      for (final stop in widget.stops)
                        if (!animatingRoute || visibleStopIds.contains(stop.id))
                          Marker(
                            markerId: MarkerId(stop.id),
                            position: LatLng(stop.lat, stop.lng),
                            // Secili durak buyuk cizilir; kart seridiyle hangi pinin
                            // eslestigi bakisla anlasilir. Pin rengi hatta gore
                            // degismez — toggle ayni anda tek hat gosterdigi icin
                            // renk zaten ayirt edici bir bilgi tasimiyor, cizgi
                            // hattin rengini veriyor.
                            icon: pins == null
                                ? BitmapDescriptor.defaultMarker
                                : (stop.id == selectedId
                                      ? pins.selected
                                      : pins.normal),
                            infoWindow: InfoWindow(
                              title: stop.name,
                              snippet: stop.lineNames.join(' · '),
                              onTap: () => widget.onStopTap(stop.id),
                            ),
                            onTap: () => widget.onStopTap(stop.id),
                          ),
                    },
                    polylines: {
                      for (final route in widget.routes)
                        Polyline(
                          polylineId: PolylineId(route.id),
                          points: [
                            for (final point
                                in plan?.route.id == route.id
                                    ? plan!.pointsAt(routeProgress)
                                    : route.points)
                              LatLng(point.lat, point.lng),
                          ],
                          color: _routeColor(route.color),
                          width: 5,
                          startCap: Cap.roundCap,
                          endCap: Cap.roundCap,
                          jointType: JointType.round,
                          consumeTapEvents: widget.onRouteTap != null,
                          onTap: () => widget.onRouteTap?.call(route),
                        ),
                    },
                    myLocationEnabled: position != null,
                    // Konum butonu sayfanin kendi yuzen butonlarinda; haritanin
                    // yerlesik butonu kart seridiyle cakisiyordu.
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  );
                },
              ),
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

/// Cozulmus durak pini gorselleri — normal ve secili.
class _StopPins {
  final BitmapDescriptor normal;
  final BitmapDescriptor selected;

  const _StopPins({required this.normal, required this.selected});
}

/// Harita yuklenene kadar duran yer tutucu. Sayfanin geri kalani — durak
/// kartlari, mesafeler — bu sirada tam calisir; bekleyen tek sey haritadir.
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
