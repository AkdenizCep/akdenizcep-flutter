import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/location_provider.dart';
import '../models/departure_point.dart';
import '../models/ring_departures.dart';
import '../models/ring_schedule.dart';
import '../models/ring_stop.dart';
import '../models/route_key.dart';
import '../models/route_shape.dart';
import '../models/stop_departures.dart';
import '../models/turkish_text.dart';
import '../services/favorite_stops_service.dart';
import '../services/route_shapes_service.dart';
import '../services/ring_service.dart';
import '../services/stops_service.dart';

final ringServiceProvider = Provider((_) => RingService());

final ringSchedulesProvider = StreamProvider<List<RingSchedule>>((ref) {
  return ref.watch(ringServiceProvider).getSchedules();
});

final stopsServiceProvider = Provider((_) => StopsService());

/// Duraklar — `assets/routes/au_duraklar.json`.
///
/// Eskiden RTDB `ring_stops` dugumunden okunuyordu; o dugum uzun sure bos
/// kaldigi icin durak arayuzunun tamami calismiyordu. Topoloji artik
/// uygulamayla birlikte geliyor, cevrimdisi da calisiyor.
final ringStopsProvider = FutureProvider<List<RingStop>>((ref) async {
  final bundle = await ref.watch(stopsServiceProvider).load();
  return bundle.stops;
});

/// Durak id -> durak. Guzergah referanslarini cozmek icin.
final ringStopMapProvider = Provider<Map<String, RingStop>>((ref) {
  final stops = ref.watch(ringStopsProvider).valueOrNull ?? const <RingStop>[];
  return {for (final stop in stops) stop.id: stop};
});

// --- Secim state'leri ------------------------------------------------------

enum RingView { schedule, map }

final ringViewProvider = StateProvider<RingView>((_) => RingView.schedule);

final isReturnDirectionProvider = StateProvider<bool>((_) => false);

final showWeekendProvider = StateProvider<bool>(
  (_) => RingDepartures.isWeekendDay(DateTime.now()),
);

// --- Turetilmis veriler ----------------------------------------------------

/// Veride bulunan hat kodlari ("au102", "au103" ...), sirali.
/// Uygulama yalnızca AÜ102 ve AÜ103 hatlarını destekler; RTDB'deki hatalı ya
/// da eski başka kayıtlar kullanıcıya seçenek olarak sunulmaz.
final availableLinesProvider = Provider<List<String>>((ref) {
  final schedules =
      ref.watch(ringSchedulesProvider).valueOrNull ?? const <RingSchedule>[];
  const supportedCodes = {'au102', 'au103'};
  final codes =
      schedules
          .map((schedule) => schedule.lineCode)
          .where(supportedCodes.contains)
          .toSet()
          .toList()
        ..sort();
  return codes;
});

/// Desteklenen hatların tarifelerinde bulunan yönler (`true` = dönüş).
final _availableDirectionsProvider = Provider<Set<bool>>((ref) {
  final lines = ref.watch(availableLinesProvider);
  final schedules =
      ref.watch(ringSchedulesProvider).valueOrNull ?? const <RingSchedule>[];
  return {
    for (final schedule in schedules)
      if (lines.contains(schedule.lineCode)) schedule.isReturn,
  };
});

/// İstenen yön hiçbir hatta yoksa veride olan yöne düşer.
final effectiveReturnDirectionProvider = Provider<bool>((ref) {
  final wanted = ref.watch(isReturnDirectionProvider);
  final directions = ref.watch(_availableDirectionsProvider);
  if (directions.isEmpty || directions.contains(wanted)) return wanted;
  return !wanted;
});

final canSwitchDirectionProvider = Provider<bool>((ref) {
  return ref.watch(_availableDirectionsProvider).length > 1;
});

/// Canli geri sayimi besleyen saniyelik nabiz.
final tickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// Tick'e bagli "simdi". Ilk kare icin `DateTime.now()`'a duser.
final nowProvider = Provider<DateTime>((ref) {
  return ref.watch(tickerProvider).valueOrNull ?? DateTime.now();
});

/// Secili yondeki her hattin hesaplanmis kalkis bilgisi — hero kartin tek
/// kaynagi. O yonde tarifesi olmayan hat atlanir.
final lineDeparturesProvider = Provider<List<LineDepartures>>((ref) {
  final lines = ref.watch(availableLinesProvider);
  final schedules =
      ref.watch(ringSchedulesProvider).valueOrNull ?? const <RingSchedule>[];
  final isReturn = ref.watch(effectiveReturnDirectionProvider);
  final showWeekend = ref.watch(showWeekendProvider);
  final now = ref.watch(nowProvider);

  final result = <LineDepartures>[];
  for (final line in lines) {
    final schedule = schedules
        .where((s) => s.lineCode == line && s.isReturn == isReturn)
        .firstOrNull;
    if (schedule == null) continue;

    result.add(
      LineDepartures(
        lineCode: line,
        departures: RingDepartures.from(
          weekdayTimes: schedule.weekday,
          weekendTimes: schedule.weekend,
          showWeekend: showWeekend,
          now: now,
        ),
      ),
    );
  }
  return result;
});

/// Tarifelerin kalkis noktasina gore gruplanmis hali (Adli Tıp, Meltem
/// Kapısı). Guzergah paketi gelene kadar bos.
final departurePointsProvider = Provider<List<DeparturePoint>>((ref) {
  final schedules =
      ref.watch(ringSchedulesProvider).valueOrNull ?? const <RingSchedule>[];
  final routes = ref.watch(routeShapesProvider).valueOrNull;
  if (routes == null) return const [];

  return DeparturePoints.group(
    schedules: schedules,
    routes: routes,
    lineCodes: ref.watch(availableLinesProvider),
  );
});

// --- Tum tarife yapragi (9c) -------------------------------------------------

/// Yapraktaki secili kalkis noktasi adi. `null` = ilk nokta. Yaprak kapaninca
/// sifirlanir.
final timetablePointProvider = StateProvider.autoDispose<String?>((_) => null);

/// Yapraktaki gun tipi. Varsayilan bugunun gun tipidir; ana ekranin
/// [showWeekendProvider]'ina dokunmaz.
final timetableWeekendProvider = StateProvider.autoDispose<bool>(
  (ref) => RingDepartures.isWeekendDay(ref.read(nowProvider)),
);

/// Yapraktaki cozulmus kalkis noktasi; secim gecersizse ilk nokta.
final timetableActivePointProvider = Provider.autoDispose<DeparturePoint?>((
  ref,
) {
  final points = ref.watch(departurePointsProvider);
  if (points.isEmpty) return null;

  final selected = ref.watch(timetablePointProvider);
  return points.firstWhere(
    (p) => p.name == selected,
    orElse: () => points.first,
  );
});

// --- Duraklar --------------------------------------------------------------

/// Bir durak ve — konum biliniyorsa — kullaniciya uzakligi.
class NearbyStop {
  final RingStop stop;

  /// Metre. Konum izni yoksa `null`.
  final double? distanceMeters;

  /// Bu duraktan gecen tarifeler (hat + yon).
  final List<RingSchedule> schedules;

  const NearbyStop({
    required this.stop,
    required this.distanceMeters,
    required this.schedules,
  });
}

/// Duraklar, konum varsa mesafeye gore sirali; yoksa guzergah sirasina gore.
final nearbyStopsProvider = Provider<List<NearbyStop>>((ref) {
  final stops = ref.watch(ringStopsProvider).valueOrNull ?? const <RingStop>[];
  if (stops.isEmpty) return const [];

  final schedules =
      ref.watch(ringSchedulesProvider).valueOrNull ?? const <RingSchedule>[];
  final position = ref.watch(userPositionProvider);
  final locationService = ref.watch(locationServiceProvider);

  // Konum yokken guzergah sirasi; verideki `stopSequence` bunu zaten veriyor.
  final ordered = [...stops]
    ..sort((a, b) {
      final byRoute = a.routeOrder.compareTo(b.routeOrder);
      return byRoute != 0 ? byRoute : a.name.compareTo(b.name);
    });

  final result = ordered.map((stop) {
    return NearbyStop(
      stop: stop,
      distanceMeters: position == null
          ? null
          : locationService.distanceInMeters(
              fromLat: position.latitude,
              fromLng: position.longitude,
              toLat: stop.lat,
              toLng: stop.lng,
            ),
      schedules: _schedulesServing(stop, schedules),
    );
  }).toList();

  if (position != null) {
    result.sort(
      (a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0),
    );
  }
  return result;
});

/// Bir duraktan gecen tum tarifelerin bugun kalan kalkislari, zamana gore
/// sirali. Durak yapragindaki kronolojik liste ve kartlardaki geri sayim
/// (listenin ilk elemani) ayni kaynaktan beslenir.
final stopDeparturesProvider = Provider.family<List<StopDeparture>, String>((
  ref,
  stopId,
) {
  final schedules = _schedulesThrough(ref, stopId);
  if (schedules.isEmpty) return const [];

  return StopDepartures.merge(
    schedules: schedules,
    routes:
        ref.watch(routeShapesProvider).valueOrNull ?? RouteShapeBundle.empty,
    showWeekend: ref.watch(showWeekendProvider),
    now: ref.watch(nowProvider),
  );
});

/// Bir duraktan gecen tarifelerin bugunku en erken kalkisi ve hatti.
/// `null` = bugun sefer kalmadi (ya da duraktan tarife gecmiyor).
final stopSoonestDepartureProvider =
    Provider.family<({String lineCode, Duration until})?, String>((
      ref,
      stopId,
    ) {
      return StopDepartures.soonest(
        schedules: _schedulesThrough(ref, stopId),
        now: ref.watch(nowProvider),
      );
    });

/// Bugun sefer kalmadiginda gosterilecek "yarin ilk kalkis" satirlari.
final stopTomorrowFirstsProvider = Provider.family<List<StopDeparture>, String>(
  (ref, stopId) {
    final schedules = _schedulesThrough(ref, stopId);
    if (schedules.isEmpty) return const [];

    return StopDepartures.tomorrowFirsts(
      schedules: schedules,
      routes:
          ref.watch(routeShapesProvider).valueOrNull ?? RouteShapeBundle.empty,
      showWeekend: ref.watch(showWeekendProvider),
      now: ref.watch(nowProvider),
    );
  },
);

List<RingSchedule> _schedulesThrough(Ref ref, String stopId) {
  final stop = ref.watch(ringStopMapProvider)[stopId];
  if (stop == null) return const [];

  final schedules =
      ref.watch(ringSchedulesProvider).valueOrNull ?? const <RingSchedule>[];
  return _schedulesServing(stop, schedules);
}

/// Kullaniciya en yakin durak. Konum yoksa veya durak verisi bossa `null`.
final nearestStopProvider = Provider<NearbyStop?>((ref) {
  final stops = ref.watch(nearbyStopsProvider);
  if (stops.isEmpty) return null;
  if (stops.first.distanceMeters == null) return null;
  return stops.first;
});

// --- Favoriler -------------------------------------------------------------

final favoriteStopsServiceProvider = Provider((_) => FavoriteStopsService());

/// Favori durak id'leri. Ilk okuma asenkron oldugu icin baslangic degeri bos
/// kumedir; disk okumasi bitince state guncellenir.
class FavoriteStopsNotifier extends StateNotifier<Set<String>> {
  final FavoriteStopsService _service;

  FavoriteStopsNotifier(this._service) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final stored = await _service.load();
    if (!mounted) return;
    state = stored;
  }

  Future<void> toggle(String stopId) async {
    final next = {...state};
    if (!next.remove(stopId)) next.add(stopId);
    state = next;
    await _service.save(next);
  }

  bool contains(String stopId) => state.contains(stopId);
}

final favoriteStopIdsProvider =
    StateNotifierProvider<FavoriteStopsNotifier, Set<String>>((ref) {
      return FavoriteStopsNotifier(ref.watch(favoriteStopsServiceProvider));
    });

/// Favori olarak isaretlenmis duraklar, [nearbyStopsProvider] sirasiyla.
final favoriteStopsProvider = Provider<List<NearbyStop>>((ref) {
  final ids = ref.watch(favoriteStopIdsProvider);
  if (ids.isEmpty) return const [];
  return ref
      .watch(nearbyStopsProvider)
      .where((n) => ids.contains(n.stop.id))
      .toList();
});

// --- Hat guzergahlari (harita cizgileri) -----------------------------------

final routeShapesServiceProvider = Provider((_) => RouteShapesService());

/// `assets/routes/au_hatlar.json` icerigi. Asset statik oldugu icin bir kez
/// okunur; servis sonucu kendi icinde cache'ler.
final routeShapesProvider = FutureProvider<RouteShapeBundle>((ref) {
  return ref.watch(routeShapesServiceProvider).load();
});

/// Ana ulaşım kartının başlığı için seçili yöndeki güzergâh. Hatlar aynı
/// noktalar arasında çalıştığı için ilk bulunan hattın güzergâhı yeterlidir.
final activeScheduleRouteShapeProvider = Provider.family<RouteShape?, bool>((
  ref,
  isReturn,
) {
  final bundle = ref.watch(routeShapesProvider).valueOrNull;
  if (bundle == null) return null;

  final wanted = directionIdFor(isReturn);
  for (final line in ref.watch(availableLinesProvider)) {
    final match = bundle.routes
        .where(
          (shape) =>
              lineCodeOf(shape.shortName) == line && shape.directionId == wanted,
        )
        .firstOrNull;
    if (match != null) return match;
  }
  return null;
});

/// Haritada cizilen hat. `null` = veri henuz gelmedi; ilk hat secilir.
final selectedRouteLineProvider = StateProvider<String?>((_) => null);

/// Haritada cizilen yon. `null` = secili hattin ilk yonu.
final selectedRouteDirectionProvider = StateProvider<int?>((_) => null);

/// Toggle'in secenekleri — veriden turetilir, kodda sabit hat listesi yok.
final routeLineNamesProvider = Provider<List<String>>((ref) {
  final bundle = ref.watch(routeShapesProvider).valueOrNull;
  return bundle?.lineNames ?? const [];
});

/// Cozulmus secim: kullanici secmediyse ilk hat. Veri gelmediyse `null`.
/// Cizgiler, pinler ve kart seridi bu tek kaynagi izler.
final activeRouteLineProvider = Provider<String?>((ref) {
  final names = ref.watch(routeLineNamesProvider);
  if (names.isEmpty) return null;

  final selected = ref.watch(selectedRouteLineProvider);
  return selected != null && names.contains(selected) ? selected : names.first;
});

/// Secili hattin veride bulunan tum yonleri.
final activeRouteLineShapesProvider = Provider<List<RouteShape>>((ref) {
  final bundle = ref.watch(routeShapesProvider).valueOrNull;
  final line = ref.watch(activeRouteLineProvider);
  if (bundle == null || line == null) return const [];

  return bundle.forLine(line);
});

/// Cozulmus yon: secim yoksa secili hattin ilk yonu.
final activeRouteDirectionProvider = Provider<int?>((ref) {
  final shapes = ref.watch(activeRouteLineShapesProvider);
  if (shapes.isEmpty) return null;

  final selected = ref.watch(selectedRouteDirectionProvider);
  return selected != null &&
          shapes.any((shape) => shape.directionId == selected)
      ? selected
      : shapes.first.directionId;
});

/// Haritada yalnizca secili hat + yonun guzergahi cizilir.
final visibleRouteShapesProvider = Provider<List<RouteShape>>((ref) {
  final shapes = ref.watch(activeRouteLineShapesProvider);
  final direction = ref.watch(activeRouteDirectionProvider);
  if (direction == null) return const [];

  return shapes.where((shape) => shape.directionId == direction).toList();
});

/// Secili hattin yon basina guzergahi — yon etiketleri buradan okunur.
final activeRouteShapeProvider = Provider.family<RouteShape?, bool>((
  ref,
  isReturn,
) {
  final shapes = ref.watch(activeRouteLineShapesProvider);
  final wanted = directionIdFor(isReturn);
  final match = shapes.where((s) => s.directionId == wanted);
  return match.isEmpty ? null : match.first;
});

// --- Harita ekrani (2b) ----------------------------------------------------

/// Harita ekraninda one cikan durak — kart seridi ile pinleri senkron tutar.
final selectedStopProvider = StateProvider<String?>((_) => null);

/// Harita ekranindaki arama kutusu.
final stopQueryProvider = StateProvider<String>((_) => '');

/// Harita ekraninda gorunen duraklar: hat + yon, sonra arama sorgusu.
///
/// Seciciler cizgiyi, pinleri ve kart seridini birlikte cevirir — ekrandaki
/// her sey ayni hat ve yone aittir.
final visibleStopsProvider = Provider<List<NearbyStop>>((ref) {
  var stops = ref.watch(nearbyStopsProvider);

  final line = ref.watch(activeRouteLineProvider);
  final direction = ref.watch(activeRouteDirectionProvider);
  if (line != null && direction != null) {
    stops = stops
        .where((nearby) => nearby.stop.servesRoute(line, direction))
        .toList();

    // Konum yokken kartlar secili guzergahin gercek durak sirasini izler.
    // Konum varsa [nearbyStopsProvider]'in mesafe sirasi korunur.
    if (stops.every((nearby) => nearby.distanceMeters == null)) {
      stops.sort((a, b) {
        final aSequence = a.stop.routeSequenceFor(line, direction) ?? 1 << 20;
        final bSequence = b.stop.routeSequenceFor(line, direction) ?? 1 << 20;
        return aSequence.compareTo(bSequence);
      });
    }
  }

  final query = normalizeForSearch(ref.watch(stopQueryProvider));
  if (query.isEmpty) return stops;

  return stops
      .where((n) => normalizeForSearch(n.stop.name).contains(query))
      .toList();
});

/// Bir duraktan gecen tarifeler.
///
/// Eskiden `schedule.stops.contains(stop.id)` ile bulunuyordu; o dizi uretimde
/// hicbir hatta girilmemisti. Artik uyelik duragin kendi `servedBy` kaydinda
/// duruyor ve tarifeye [routeShapeIdFor] koprusuyle baglaniyor.
List<RingSchedule> _schedulesServing(
  RingStop stop,
  List<RingSchedule> schedules,
) {
  final served = stop.servedBy.map((s) => s.routeShapeId).toSet();
  return schedules
      .where((s) => served.contains(routeShapeIdFor(s.lineCode, s.isReturn)))
      .toList();
}
