import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/providers/location_provider.dart';
import '../../models/ring_stop.dart';
import '../../models/route_shape.dart';
import '../../providers/ring_provider.dart';

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

  const StopsMap({
    super.key,
    required this.stops,
    required this.onStopTap,
    this.routes = const [],
    this.onRouteTap,
    this.mapType = MapType.normal,
    this.recenterTick = 0,
  });

  @override
  ConsumerState<StopsMap> createState() => _StopsMapState();
}

class _StopsMapState extends ConsumerState<StopsMap> {
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
  bool _pinsRequested = false;

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
    if (widget.recenterTick != oldWidget.recenterTick) _recenterOnUser();
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
    _canMount.dispose();
    _isReady.dispose();
    _pins.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(userPositionProvider);
    final selectedId = ref.watch(selectedStopProvider);

    // Konum sonradan gelirse kamerayi kullaniciya tasi.
    ref.listen(userPositionProvider, (previous, next) {
      if (next == null || previous != null) return;
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(next.latitude, next.longitude), 15.5),
      );
    });

    // Kart seridinde baska bir durak one ciktiginda kamera oraya gider.
    ref.listen(selectedStopProvider, (previous, next) {
      if (next == null || next == previous) return;
      final matches = widget.stops.where((s) => s.id == next);
      if (matches.isEmpty) return;
      final stop = matches.first;
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(stop.lat, stop.lng)),
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
            ValueListenableBuilder<_StopPins?>(
              valueListenable: _pins,
              builder: (context, pins, child) => GoogleMap(
                initialCameraPosition: CameraPosition(target: target, zoom: 15),
                mapType: widget.mapType,
                onMapCreated: (controller) {
                  _controller = controller;
                  _isReady.value = true;
                  _fitToRoutes();
                },
                markers: {
                  for (final stop in widget.stops)
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
                        for (final point in route.points)
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
