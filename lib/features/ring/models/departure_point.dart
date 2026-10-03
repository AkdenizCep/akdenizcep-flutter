import 'ring_schedule.dart';
import 'route_key.dart';
import 'route_shape.dart';
import 'turkish_text.dart';

/// Hatlarin otobusu **kalkardigi** nokta: "Adli Tıp", "Meltem Kapısı".
///
/// Saf Dart — Flutter veya Riverpod bilmez. Ayni noktadan kalkan tum tarifeler
/// (AÜ102 ve AÜ103) tek nesnede toplanir; ana ekran yon degil kalkis noktasi
/// gosterir.
class DeparturePoint {
  final String name;

  /// Bu noktadan kalkan tarifeler, hat sirasiyla.
  final List<RingSchedule> schedules;

  /// Kalkis noktasinin konumu: guzergah cizgisinin ilk noktasi. Kullaniciya
  /// yakinligi siralamak icin kullanilir; yoksa `null`.
  final RoutePoint? location;

  const DeparturePoint({
    required this.name,
    required this.schedules,
    this.location,
  });
}

abstract final class DeparturePoints {
  /// Guzergahin kalkis noktasi adi, `headsign`'in ilk parcasi:
  /// "ADLİ TIP → MELTEM KAPISI" -> "Adli Tıp".
  ///
  /// Durak listesinden okunamaz: AU102_0 ve AU103_0 icin `stopSequence`
  /// 2'den basliyor (gercek kalkis duragi kampus disinda, veri setinde yok);
  /// AU102_1'in ilk duragi ise "Dogu Kapisi Girisi" — kalkis noktasi degil.
  static String? nameOf(RouteShape? shape) {
    if (shape == null) return null;

    final origin = shape.headsign.split('→').first.trim();
    return origin.isEmpty ? null : turkishTitleCase(origin);
  }

  /// Guzergahin varis noktasi adi, `headsign`'in son parcasi:
  /// "ADLİ TIP → MELTEM KAPISI" -> "Meltem Kapısı". `headsign` okun iki
  /// yaninı da vermiyorsa `null`.
  static String? destinationOf(RouteShape? shape) {
    if (shape == null) return null;

    final parts = shape.headsign.split('→');
    if (parts.length < 2) return null;

    final destination = parts.last.trim();
    return destination.isEmpty ? null : turkishTitleCase(destination);
  }

  /// Tarifeleri kalkis noktasina gore gruplar.
  ///
  /// [lineCodes] desteklenen hatlari ve gosterim sirasini belirler. Guzergahi
  /// bulunamayan tarife atlanir — adi uydurulmaz. Noktalar ilk gidis yonunden
  /// baslayarak sabit sirayla gelir.
  static List<DeparturePoint> group({
    required List<RingSchedule> schedules,
    required RouteShapeBundle routes,
    required List<String> lineCodes,
  }) {
    final supported =
        [
          for (final schedule in schedules)
            if (lineCodes.contains(schedule.lineCode)) schedule,
        ]..sort((a, b) {
          if (a.isReturn != b.isReturn) return a.isReturn ? 1 : -1;
          return lineCodes
              .indexOf(a.lineCode)
              .compareTo(lineCodes.indexOf(b.lineCode));
        });

    final names = <String>[];
    final grouped = <String, List<RingSchedule>>{};
    final locations = <String, RoutePoint?>{};

    for (final schedule in supported) {
      final id = routeShapeIdFor(schedule.lineCode, schedule.isReturn);
      final shape = routes.routes.where((r) => r.id == id).firstOrNull;
      final name = nameOf(shape);
      if (name == null) continue;

      if (!grouped.containsKey(name)) names.add(name);
      grouped.putIfAbsent(name, () => []).add(schedule);
      if (shape!.points.isNotEmpty) {
        locations.putIfAbsent(name, () => shape.points.first);
      }
    }

    return [
      for (final name in names)
        DeparturePoint(
          name: name,
          schedules: grouped[name]!,
          location: locations[name],
        ),
    ];
  }
}
