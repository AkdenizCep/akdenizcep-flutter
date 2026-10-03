import 'package:akdenizcep/features/ring/models/departure_point.dart';
import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/models/route_shape.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

void main() {
  RingSchedule schedule(String id, List<String> weekday) =>
      RingSchedule(lineId: id, weekday: weekday, weekend: const []);

  final schedules = [
    schedule('au103_donus', ['14:10', '14:55']),
    schedule('au102_donus', ['14:00', '14:40']),
    schedule('au103_gidis', ['14:20', '14:35', '14:50']),
    schedule('au102_gidis', ['14:15', '14:30', '14:45']),
  ];
  const lines = ['au102', 'au103'];

  group('DeparturePoints.nameOf', () {
    RouteShape shape(String headsign) =>
        routeBundle().routes.first.copyWith(headsign: headsign);

    test('headsign\'in ilk parcasini kalkis noktasi sayar', () {
      expect(
        DeparturePoints.nameOf(shape('ADLİ TIP → MELTEM KAPISI')),
        'Adli Tıp',
      );
      expect(
        DeparturePoints.nameOf(shape('MELTEM KAPISI → ADLİ TIP')),
        'Meltem Kapısı',
      );
    });

    test('ara duraklı headsign\'da yalnizca ilk parca', () {
      expect(
        DeparturePoints.nameOf(shape('ADLİ TIP → TEKNOKENT → MELTEM KAPISI')),
        'Adli Tıp',
      );
    });

    test('bos headsign veya guzergah yoksa null', () {
      expect(DeparturePoints.nameOf(shape('')), isNull);
      expect(DeparturePoints.nameOf(null), isNull);
    });
  });

  group('DeparturePoints.group', () {
    test('tarifeleri kalkis noktasina gore gruplar, gidis once', () {
      final points = DeparturePoints.group(
        schedules: schedules,
        routes: routeBundle(),
        lineCodes: lines,
      );

      expect([for (final p in points) p.name], ['Adli Tıp', 'Meltem Kapısı']);
      expect(
        [for (final s in points.first.schedules) s.lineId],
        ['au102_gidis', 'au103_gidis'],
      );
      expect(
        [for (final s in points.last.schedules) s.lineId],
        ['au102_donus', 'au103_donus'],
      );
      expect(points.first.location, isNotNull);
    });

    test('desteklenmeyen hat ve guzergahsiz tarife atlanir', () {
      final points = DeparturePoints.group(
        schedules: [
          ...schedules,
          schedule('au999_gidis', ['10:00']),
        ],
        routes: routeBundle(lines: const ['AÜ102']),
        lineCodes: lines,
      );

      // AÜ103 icin guzergah yok -> yalnizca AÜ102'ler.
      expect(points.expand((p) => p.schedules).map((s) => s.lineCode), [
        'au102',
        'au102',
      ]);
    });

    test('guzergah paketi bos ise hicbir sey uydurmaz', () {
      expect(
        DeparturePoints.group(
          schedules: schedules,
          routes: RouteShapeBundle.empty,
          lineCodes: lines,
        ),
        isEmpty,
      );
    });
  });
}
