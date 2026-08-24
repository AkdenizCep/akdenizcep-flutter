import 'dart:convert';
import 'dart:io';

import 'package:akdenizcep/features/ring/models/ring_stop.dart';
import 'package:akdenizcep/features/ring/models/route_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// Durak verisi artik RTDB'den degil asset'ten geliyor. Bu testler gercek
/// dosyayi okur — sema bozulursa ya da koordinat sirasi karisirsa burada patlar.
void main() {
  final bundle = RingStopBundle.fromJson(
    jsonDecode(File('assets/routes/au_duraklar.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  group('gercek asset', () {
    test('33 durak, 40 hizmet kaydi okunur', () {
      expect(bundle.schemaVersion, 1);
      expect(bundle.stops, hasLength(33));
      expect(
        bundle.stops.fold<int>(0, (sum, s) => sum + s.servedBy.length),
        40,
      );
    });

    test('alti transfer duragi isaretli', () {
      final transfers = bundle.stops.where((s) => s.isTransfer).toList();

      expect(transfers, hasLength(6));
      // Transfer olmak birden fazla hatta hizmet vermek demek.
      for (final stop in transfers) {
        expect(stop.lineNames.length, greaterThan(1), reason: stop.name);
      }
    });

    test('koordinatlar [lat, lon] olarak okunur', () {
      for (final stop in bundle.stops) {
        expect(stop.lat, inInclusiveRange(36.88, 36.91), reason: stop.id);
        expect(stop.lng, inInclusiveRange(30.63, 30.67), reason: stop.id);
      }
    });

    test('her durak en az bir hatta hizmet verir', () {
      for (final stop in bundle.stops) {
        expect(stop.servedBy, isNotEmpty, reason: stop.id);
      }
    });

    test('yalnizca AÜ102 ve AÜ103 var', () {
      final lines = {
        for (final stop in bundle.stops) ...stop.lineNames,
      };

      expect(lines, {'AÜ102', 'AÜ103'});
    });
  });

  group('ad bicimlendirme', () {
    RingStop byId(String id) => bundle.stops.firstWhere((s) => s.id == id);

    test('kampus oneki kirpilir ve baslik bicimine gecer', () {
      final stop = byId('10955');

      expect(stop.rawName, 'AKDENİZ ÜNİVERSİTESİ MERKEZİ YEMEKHANE');
      expect(stop.name, 'Merkezi Yemekhane');
    });

    test('taraf eki addan ayrilir', () {
      final stop = byId('11506');

      expect(stop.name, 'Edebiyat Fakültesi');
      expect(stop.side, 1);
    });

    test('veri hatasi duzeltilir', () {
      final stop = byId('10956');

      expect(stop.name, 'İktisadi ve İdari Bilimler Fakültesi');
    });

    test('hicbir ad tamami buyuk harf kalmaz', () {
      for (final stop in bundle.stops) {
        expect(
          stop.name,
          isNot(equals(stop.name.toUpperCase())),
          reason: stop.name,
        );
      }
    });
  });

  group('guzergah baglantisi', () {
    test('servedBy kimlikleri hat kopruusuyle uretilebilir', () {
      final stop = bundle.stops.firstWhere((s) => s.id == '14373');
      final ids = stop.servedBy.map((s) => s.routeShapeId).toSet();

      // AÜ102 dönüş + AÜ103 gidiş + AÜ103 dönüş
      expect(ids, contains(routeShapeIdFor('au102', true)));
      expect(ids, contains(routeShapeIdFor('au103', false)));
      expect(ids, contains(routeShapeIdFor('au103', true)));
      expect(ids, isNot(contains(routeShapeIdFor('au102', false))));
    });

    test('routeOrder en kucuk stopSequence degerini verir', () {
      final stop = bundle.stops.firstWhere((s) => s.id == '14373');

      // AU102_1: 1, AU103_0: 14, AU103_1: 1
      expect(stop.routeOrder, 1);
    });

    test('servesLine hat uyeligini soyler', () {
      final stop = bundle.stops.firstWhere((s) => s.id == '14145');

      expect(stop.servesLine('AÜ103'), isTrue);
      expect(stop.servesLine('AÜ102'), isFalse);
    });

    test('bir hattin duraklari sirali dizilebilir', () {
      final onLine = bundle.stops.where((s) => s.servesLine('AÜ102')).toList();

      expect(onLine, isNotEmpty);
      expect(onLine.length, lessThan(bundle.stops.length));
    });
  });

  test('toJson -> fromJson tur kaybi yasatmaz', () {
    final round = RingStopBundle.fromJson(bundle.toJson());

    expect(round.stops, hasLength(bundle.stops.length));
    expect(round.stops.first.name, bundle.stops.first.name);
    expect(round.stops.first.lng, bundle.stops.first.lng);
    expect(round.stops.first.servedBy.length, bundle.stops.first.servedBy.length);
  });
}
