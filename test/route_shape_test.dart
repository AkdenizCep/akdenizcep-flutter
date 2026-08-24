import 'dart:convert';
import 'dart:io';

import 'package:akdenizcep/features/ring/models/route_shape.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hat guzergahlari saf Dart model — asset'siz, haritasiz test edilebilir.
///
/// Kritik detay: `points` dizisinde sira **[enlem, boylam]**, GeoJSON'un
/// [lon, lat] sirasi degil. Yanlis parse edilirse cizgiler Antalya yerine
/// Somali acigina duser, bu yuzden ayri bir testi var.
void main() {
  final bundle = RouteShapeBundle.fromJson(
    jsonDecode(
          File('assets/routes/au_hatlar.json').readAsStringSync(),
        )
        as Map<String, dynamic>,
  );

  group('gercek asset', () {
    test('dort guzergah okunur', () {
      expect(bundle.schemaVersion, 1);
      expect(bundle.routes, hasLength(4));
      expect(
        bundle.routes.map((r) => r.id),
        ['AU102_0', 'AU102_1', 'AU103_0', 'AU103_1'],
      );
    });

    test('toggle secenekleri veriden turetilir', () {
      expect(bundle.lineNames, ['AÜ102', 'AÜ103']);
    });

    test('bir hat secilince iki yonu de gelir', () {
      final line = bundle.forLine('AÜ103');

      expect(line, hasLength(2));
      expect(line.map((r) => r.directionId), [0, 1]);
      expect(line.first.label, 'AÜ103 · Meltem Kapısı yönü');
    });

    test('koordinatlar [enlem, boylam] sirasinda okunur', () {
      final first = bundle.routes.first.points.first;

      // Akdeniz Universitesi kampusu: ~36.9 K, ~30.65 D.
      expect(first.lat, closeTo(36.8997, 0.001));
      expect(first.lng, closeTo(30.6564, 0.001));
    });

    test('her guzergah bildirdigi kadar nokta icerir', () {
      for (final route in bundle.routes) {
        expect(route.points, isNotEmpty, reason: route.id);
        expect(
          route.points.every((p) => p.lat > 36 && p.lat < 37),
          isTrue,
          reason: '${route.id} enlemleri kampus disinda',
        );
        expect(
          route.points.every((p) => p.lng > 30 && p.lng < 31),
          isTrue,
          reason: '${route.id} boylamlari kampus disinda',
        );
      }
    });

    test('renkler #RRGGBB bicimindedir', () {
      for (final route in bundle.routes) {
        expect(
          RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(route.color),
          isTrue,
          reason: '${route.id}: ${route.color}',
        );
      }
    });

    test('toJson -> fromJson tur kaybi yasatmaz', () {
      final round = RouteShapeBundle.fromJson(bundle.toJson());

      expect(round.routes, hasLength(bundle.routes.length));
      expect(round.routes.first.points.length, bundle.routes.first.points.length);
      expect(round.routes.first.points.first.lat, bundle.routes.first.points.first.lat);
    });
  });

  group('hat sayisi degisirse', () {
    test('uc hatli veride toggle uc secenek verir', () {
      final extended = RouteShapeBundle.fromJson({
        'schemaVersion': 1,
        'bounds': {'south': 36, 'west': 30, 'north': 37, 'east': 31},
        'routes': [
          for (final name in ['AÜ102', 'AÜ103', 'AÜ104'])
            {
              'id': '${name}_0',
              'shortName': name,
              'directionId': 0,
              'headsign': 'A → B',
              'label': '$name · B yönü',
              'color': '#1565C0',
              'lengthKm': 1.0,
              'bounds': {'south': 36, 'west': 30, 'north': 37, 'east': 31},
              'points': [
                [36.9, 30.65],
              ],
            },
        ],
      });

      expect(extended.lineNames, ['AÜ102', 'AÜ103', 'AÜ104']);
    });
  });
}
