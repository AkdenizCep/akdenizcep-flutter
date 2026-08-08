import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

RingSchedule scheduleFor(String lineId) =>
    RingSchedule(lineId: lineId, weekday: const [], weekend: const []);

void main() {
  group('lineCode', () {
    test('"au102_gidis" bicimini cozer', () {
      expect(scheduleFor('au102_gidis').lineCode, 'au102');
      expect(scheduleFor('au102_donus').lineCode, 'au102');
    });

    test('"au_102_gidis" bicimini de ayni koda cozer', () {
      // Regresyon: ara alt cizgi temizlenmezse hat kodu "au" cikiyordu ve
      // AU102 ile AU103 tek dugmede birlesiyordu.
      expect(scheduleFor('au_102_gidis').lineCode, 'au102');
      expect(scheduleFor('au_102_donus').lineCode, 'au102');
      expect(scheduleFor('au_103_gidis').lineCode, 'au103');
    });

    test('iki bicim ayni hat kodunu uretir', () {
      expect(
        scheduleFor('au_102_gidis').lineCode,
        scheduleFor('au102_gidis').lineCode,
      );
    });

    test('farkli hatlar farkli kod uretir', () {
      final codes = [
        'au_102_gidis',
        'au_102_donus',
        'au_103_gidis',
        'au_103_donus',
      ].map((id) => scheduleFor(id).lineCode).toSet();

      expect(codes, {'au102', 'au103'});
    });

    test('buyuk harfli anahtarlari kucuk harfe normalize eder', () {
      expect(scheduleFor('AU_102_GIDIS').lineCode, 'au102');
    });

    test('yon eki olmayan anahtari oldugu gibi birakir', () {
      expect(scheduleFor('line_1').lineCode, 'line1');
    });
  });

  group('isReturn', () {
    test('donus anahtarlarini isaretler', () {
      expect(scheduleFor('au_102_donus').isReturn, isTrue);
      expect(scheduleFor('au102_donus').isReturn, isTrue);
    });

    test('gidis anahtarlarini isaretlemez', () {
      expect(scheduleFor('au_102_gidis').isReturn, isFalse);
      expect(scheduleFor('au102_gidis').isReturn, isFalse);
    });
  });

  group('fromJson', () {
    test('stops alani yoksa bos liste doner', () {
      final schedule = RingSchedule.fromJson('au_102_gidis', {
        'weekday': ['07:30'],
        'weekend': ['09:00'],
      });

      expect(schedule.stops, isEmpty);
      expect(schedule.weekday, ['07:30']);
      expect(schedule.lineCode, 'au102');
    });

    test('stops alani varsa sirasini korur', () {
      final schedule = RingSchedule.fromJson('au_102_gidis', {
        'stops': ['durak_1', 'durak_2', 'durak_3'],
      });

      expect(schedule.stops, ['durak_1', 'durak_2', 'durak_3']);
    });
  });
}
