import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/location_provider.dart';
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

/// `null` = ilk hat. Gercek deger [activeLineProvider] ile cozulur.
final selectedLineProvider = StateProvider<String?>((_) => null);

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

/// Secili hat, secim yoksa ilk hat. Hat hic yoksa `null`.
final activeLineProvider = Provider<String?>((ref) {
  final lines = ref.watch(availableLinesProvider);
  if (lines.isEmpty) return null;

  final selected = ref.watch(selectedLineProvider);
  if (selected != null && lines.contains(selected)) return selected;
  return lines.first;
});

/// Secili hattin iki yonu de. Yon degistirmenin mumkun olup olmadigini
/// belirlemek icin kullanilir.
final activeLineSchedulesProvider = Provider<List<RingSchedule>>((ref) {
  final line = ref.watch(activeLineProvider);
  if (line == null) return const [];

  final schedules =
      ref.watch(ringSchedulesProvider).valueOrNull ?? const <RingSchedule>[];
  return schedules.where((s) => s.lineCode == line).toList();
});

/// Hat + yon birlesimiyle secili tarife.
final selectedScheduleProvider = Provider<RingSchedule?>((ref) {
  final schedules = ref.watch(activeLineSchedulesProvider);
  if (schedules.isEmpty) return null;

  final isReturn = ref.watch(isReturnDirectionProvider);
  for (final schedule in schedules) {
    if (schedule.isReturn == isReturn) return schedule;
  }
  // Hat tek yonluyse eldeki tek tarifeye dus.
  return schedules.first;
});

/// İstenen yön veride yoksa gerçekten gösterilen tarifenin yönüne düşer.
final effectiveReturnDirectionProvider = Provider<bool>((ref) {
  final schedule = ref.watch(selectedScheduleProvider);
  return schedule?.isReturn ?? ref.watch(isReturnDirectionProvider);
});

final canSwitchDirectionProvider = Provider<bool>((ref) {
  final directions = ref
      .watch(activeLineSchedulesProvider)
      .map((schedule) => schedule.isReturn)
      .toSet();
  return directions.length > 1;
});

/// Canli geri sayimi besleyen saniyelik nabiz.
final tickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// Tick'e bagli "simdi". Ilk kare icin `DateTime.now()`'a duser.
final nowProvider = Provider<DateTime>((ref) {
  return ref.watch(tickerProvider).valueOrNull ?? DateTime.now();
});

/// Secili tarifenin hesaplanmis kalkis bilgisi — hero kartin tek kaynagi.
final departuresProvider = Provider<RingDepartures>((ref) {
  final schedule = ref.watch(selectedScheduleProvider);
  if (schedule == null) return RingDepartures.empty;

  return RingDepartures.from(
    weekdayTimes: schedule.weekday,
    weekendTimes: schedule.weekend,
    showWeekend: ref.watch(showWeekendProvider),
    now: ref.watch(nowProvider),
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

/// Ana ulaşım ve tam tarife ekranlarında seçili hat + yönün güzergâhı.
final activeScheduleRouteShapeProvider = Provider.family<RouteShape?, bool>((
  ref,
  isReturn,
) {
  final bundle = ref.watch(routeShapesProvider).valueOrNull;
  final line = ref.watch(activeLineProvider);
  if (bundle == null || line == null) return null;

  final wanted = directionIdFor(isReturn);
  final matches = bundle.routes.where(
    (shape) =>
        lineCodeOf(shape.shortName) == line && shape.directionId == wanted,
  );
  return matches.isEmpty ? null : matches.first;
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
