import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/models/route_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// RTDB tarife anahtarlari ("au_102_gidis") ile asset guzergah kimlikleri
/// ("AU102_0") arasindaki kopru. Yanlis eslesirse saatler ters yone baglanir,
/// bu yuzden iki kaynak da gercek bicimleriyle test edilir.
void main() {
  group('lineCodeOf', () {
    test('Turkce hat adini kod bicimine cevirir', () {
      expect(lineCodeOf('AÜ102'), 'au102');
      expect(lineCodeOf('AÜ103'), 'au103');
    });

    test('RingSchedule.lineCode ile ayni bicimi uretir', () {
      // Uretimde anahtar iki bicimde giriliyor; ikisi de ayni hatta inmeli.
      final dotted = RingSchedule(
        lineId: 'au_102_gidis',
        weekday: const [],
        weekend: const [],
      );
      final plain = RingSchedule(
        lineId: 'au102_gidis',
        weekday: const [],
        weekend: const [],
      );

      expect(dotted.lineCode, lineCodeOf('AÜ102'));
      expect(plain.lineCode, lineCodeOf('AÜ102'));
    });
  });

  group('yon eslesmesi', () {
    test('gidis directionId 0', () {
      expect(kGidisDirectionId, 0);
      expect(directionIdFor(false), 0);
      expect(directionIdFor(true), 1);
    });

    test('isReturnFor tersini verir', () {
      expect(isReturnFor(0), isFalse);
      expect(isReturnFor(1), isTrue);
    });

    test('ileri ve geri donusum birbirini bozmaz', () {
      for (final isReturn in [true, false]) {
        expect(isReturnFor(directionIdFor(isReturn)), isReturn);
      }
    });
  });

  group('routeShapeIdFor', () {
    test('asset kimliklerini uretir', () {
      expect(routeShapeIdFor('au102', false), 'AU102_0');
      expect(routeShapeIdFor('au102', true), 'AU102_1');
      expect(routeShapeIdFor('au103', false), 'AU103_0');
      expect(routeShapeIdFor('au103', true), 'AU103_1');
    });

    test('Turkce hat adiyla da calisir', () {
      expect(routeShapeIdFor('AÜ103', false), 'AU103_0');
    });

    test('gercek tarife anahtarindan uretilebilir', () {
      final schedule = RingSchedule(
        lineId: 'au_103_donus',
        weekday: const [],
        weekend: const [],
      );

      expect(
        routeShapeIdFor(schedule.lineCode, schedule.isReturn),
        'AU103_1',
      );
    });
  });
}
