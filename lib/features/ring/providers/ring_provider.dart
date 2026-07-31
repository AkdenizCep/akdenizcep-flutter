import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/location_provider.dart';
import '../models/ring_departures.dart';
import '../models/ring_schedule.dart';
import '../models/ring_stop.dart';
import '../services/ring_service.dart';

final ringServiceProvider = Provider((_) => RingService());

final ringSchedulesProvider = StreamProvider<List<RingSchedule>>((ref) {
  return ref.watch(ringServiceProvider).getSchedules();
});

final ringStopsProvider = StreamProvider<List<RingStop>>((ref) {
  return ref.watch(ringServiceProvider).getStops();
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
/// Hat listesi RTDB'den turetilir — kodda sabit hat listesi tutulmaz.
final availableLinesProvider = Provider<List<String>>((ref) {
  final schedules =
      ref.watch(ringSchedulesProvider).valueOrNull ?? const <RingSchedule>[];
  final codes = schedules.map((s) => s.lineCode).toSet().toList()..sort();
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

  final ordered = _stopsInRouteOrder(stops, schedules);

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
      schedules: schedules.where((s) => s.stops.contains(stop.id)).toList(),
    );
  }).toList();

  if (position != null) {
    result.sort(
      (a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0),
    );
  }
  return result;
});

/// Kullaniciya en yakin durak. Konum yoksa veya durak verisi bossa `null`.
final nearestStopProvider = Provider<NearbyStop?>((ref) {
  final stops = ref.watch(nearbyStopsProvider);
  if (stops.isEmpty) return null;
  if (stops.first.distanceMeters == null) return null;
  return stops.first;
});

/// Duraklari guzergah sirasina gore dizer; hicbir hatta gecmeyen duraklar
/// sona alinir. Konum yokken listenin rastgele siralanmasini onler.
List<RingStop> _stopsInRouteOrder(
  List<RingStop> stops,
  List<RingSchedule> schedules,
) {
  final order = <String, int>{};
  var cursor = 0;
  for (final schedule in schedules) {
    for (final stopId in schedule.stops) {
      order.putIfAbsent(stopId, () => cursor++);
    }
  }

  final ordered = [...stops];
  ordered.sort((a, b) {
    final ai = order[a.id] ?? order.length;
    final bi = order[b.id] ?? order.length;
    if (ai != bi) return ai.compareTo(bi);
    return a.name.compareTo(b.name);
  });
  return ordered;
}
