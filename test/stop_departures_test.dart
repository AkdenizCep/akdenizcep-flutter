import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/models/stop_departures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

/// [StopDepartures] saf Dart oldugu icin Firebase olmadan test edilebilir.
/// Durak yapragindaki kronolojik liste ve yakindaki durak kartlarindaki geri
/// sayim tamamen buradan gelir.
void main() {
  // 2026-07-27 bir Pazartesi (hafta ici).
  final monday = DateTime(2026, 7, 27, 8, 48);
  // 2026-08-01 bir Cumartesi (hafta sonu).
  final saturday = DateTime(2026, 8, 1, 10, 15);

  // Yon metinleri guzergah verisinden okunuyor; tarifenin `stops` dizisinden
  // degil (o dizi uretimde hicbir hatta girilmemisti).
  final routes = routeBundle();

  // AU102 gidis: durak_1 -> durak_3, kalkislar 08:55 / 09:09 / 09:21
  final au102 = RingSchedule(
    lineId: 'au102_gidis',
    weekday: const ['06:31', '08:55', '09:09', '09:21'],
    weekend: const ['10:30', '12:30'],
    stops: const ['durak_1', 'durak_2', 'durak_3'],
  );

  // AU103 donus: durak_3 -> durak_1, kalkislar 08:51 / 09:01 / 09:11
  final au103 = RingSchedule(
    lineId: 'au103_donus',
    weekday: const ['06:41', '08:51', '09:01', '09:11'],
    weekend: const [],
    stops: const ['durak_3', 'durak_2', 'durak_1'],
  );

  List<StopDeparture> merge({
    required List<RingSchedule> schedules,
    bool showWeekend = false,
    DateTime? now,
  }) {
    return StopDepartures.merge(
      schedules: schedules,
      routes: routes,
      showWeekend: showWeekend,
      now: now ?? monday,
    );
  }

  group('merge', () {
    test('iki hattin kalkislarini zamana gore ic ice sirali verir', () {
      final result = merge(schedules: [au102, au103]);

      expect(
        result.map((d) => '${d.lineCode} ${d.time}').toList(),
        ['au103 08:51', 'au102 08:55', 'au103 09:01', 'au102 09:09',
         'au103 09:11', 'au102 09:21'],
      );
    });

    test('gecmis kalkislari listeye almaz', () {
      final result = merge(schedules: [au102, au103]);

      expect(result.map((d) => d.time), isNot(contains('06:31')));
      expect(result.map((d) => d.time), isNot(contains('06:41')));
    });

    test('kalan sureyi kalkis noktasindan hesaplar', () {
      final result = merge(schedules: [au103]);

      // 08:48 -> 08:51
      expect(result.first.until, const Duration(minutes: 3));
    });

    test('yon metnini guzergah etiketinden uretir', () {
      final result = merge(schedules: [au102, au103]);

      // au102 gidis, au103 donus.
      expect(
        result.firstWhere((d) => d.lineCode == 'au102').direction,
        'Meltem Kapısı yönü',
      );
      expect(
        result.firstWhere((d) => d.lineCode == 'au103').direction,
        'Adli Tıp yönü',
      );
    });

    test('guzergah bulunamazsa gidis/donus etiketine duser', () {
      final unknownLine = RingSchedule(
        lineId: 'au104_donus',
        weekday: const ['09:00'],
        weekend: const [],
      );

      final result = merge(schedules: [unknownLine]);

      expect(result.single.direction, 'Dönüş');
    });
  });

  group('nextTwo', () {
    test('ayni tarifedeki sonraki iki kalkisi verir', () {
      final result = merge(schedules: [au102, au103]);
      final first = result.first;

      expect(first.time, '08:51');
      expect(first.nextTwo, ['09:01', '09:11']);
    });

    test('iki kalkis kalmadiysa kisalir, hata vermez', () {
      final result = merge(schedules: [au102, au103]);

      // au103 09:01 -> ayni tarifede yalnizca 09:11 kaldi.
      expect(result[2].nextTwo, ['09:11']);
      // Her tarifenin son kalkisinda "sonrasi" bilgisi yoktur.
      expect(result[4].nextTwo, isEmpty);
      expect(result.last.nextTwo, isEmpty);
    });
  });

  group('gun tipi', () {
    test('hafta sonu secildiginde hafta sonu dizisi kullanilir', () {
      final result = merge(
        schedules: [au102, au103],
        showWeekend: true,
        now: saturday,
      );

      expect(result.map((d) => d.time), ['10:30', '12:30']);
    });

    test('secili gun tipi bugun degilse canli liste bos kalir', () {
      // Pazartesi gunu hafta sonu tarifesine bakiliyor: geri sayim anlamsiz.
      final result = merge(schedules: [au102], showWeekend: true);

      expect(result, isEmpty);
    });

    test('bugun sefer kalmadiysa bos liste doner', () {
      final result = merge(
        schedules: [au102, au103],
        now: DateTime(2026, 7, 27, 23, 30),
      );

      expect(result, isEmpty);
    });

    test('tarife girilmemisse bos liste doner', () {
      expect(merge(schedules: const []), isEmpty);
    });
  });

  group('tomorrowFirsts', () {
    test('hat basina yarinin ilk kalkisini verir', () {
      final result = StopDepartures.tomorrowFirsts(
        schedules: [au102, au103],
        routes: routes,
        showWeekend: false,
        now: DateTime(2026, 7, 27, 23, 30),
      );

      expect(
        result.map((d) => '${d.lineCode} ${d.time}').toList(),
        ['au102 06:31', 'au103 06:41'],
      );
    });

    test('yarinin gun tipi farkliysa o gunun dizisini kullanir', () {
      // 2026-07-31 Cuma; yarin Cumartesi -> hafta sonu dizisi.
      final result = StopDepartures.tomorrowFirsts(
        schedules: [au102, au103],
        routes: routes,
        showWeekend: false,
        now: DateTime(2026, 7, 31, 23, 30),
      );

      // au103'un hafta sonu tarifesi bos — satiri hic cizilmez.
      expect(result.map((d) => '${d.lineCode} ${d.time}').toList(), [
        'au102 10:30',
      ]);
    });
  });
}
