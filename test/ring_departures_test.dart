import 'package:akdenizcep/features/ring/models/ring_departures.dart';
import 'package:flutter_test/flutter_test.dart';

/// [RingDepartures] saf Dart oldugu icin Firebase olmadan test edilebilir.
/// Ring sayfasindaki her sure hesabi buradan gelir.
void main() {
  // 2026-07-27 bir Pazartesi (hafta ici).
  final monday = DateTime(2026, 7, 27, 13, 8);
  // 2026-08-01 bir Cumartesi (hafta sonu).
  final saturday = DateTime(2026, 8, 1, 10, 15);

  const weekday = ['07:30', '08:00', '13:20', '13:50', '18:00'];
  const weekend = ['09:00', '11:00', '14:00'];

  RingDepartures build({
    required bool showWeekend,
    required DateTime now,
    List<String> weekdayTimes = weekday,
    List<String> weekendTimes = weekend,
  }) {
    return RingDepartures.from(
      weekdayTimes: weekdayTimes,
      weekendTimes: weekendTimes,
      showWeekend: showWeekend,
      now: now,
    );
  }

  group('bugunun tarifesi', () {
    test('siradaki kalkisi ve kalan sureyi bulur', () {
      final result = build(showWeekend: false, now: monday);

      expect(result.isToday, isTrue);
      expect(result.nextTime, '13:20');
      expect(result.untilNext, const Duration(minutes: 12));
    });

    test('kalkis saatinde henuz gecmis sayilmaz', () {
      final result = build(
        showWeekend: false,
        now: DateTime(2026, 7, 27, 13, 20),
      );

      expect(result.nextTime, '13:20');
      expect(result.untilNext, Duration.zero);
    });

    test('kalan kalkislari siradakinden itibaren listeler', () {
      final result = build(showWeekend: false, now: monday);

      expect(result.upcoming, ['13:20', '13:50', '18:00']);
    });

    test('onceki kalkisa gore ilerleme hesaplar', () {
      // 08:00 ile 13:20 arasi 320 dk; 13:08'de 308 dk gecmis.
      final result = build(showWeekend: false, now: monday);

      expect(result.previousTime, '08:00');
      expect(result.progress, closeTo(308 / 320, 0.001));
    });

    test('gunun ilk kalkisindan once ilerleme yoktur', () {
      final result = build(
        showWeekend: false,
        now: DateTime(2026, 7, 27, 6, 0),
      );

      expect(result.nextTime, '07:30');
      expect(result.previousTime, isNull);
      expect(result.progress, isNull);
    });
  });

  group('gun bittiginde', () {
    test('siradaki kalkis yoktur ve yarinin ilki gosterilir', () {
      final result = build(
        showWeekend: false,
        now: DateTime(2026, 7, 27, 19, 0),
      );

      expect(result.isToday, isTrue);
      expect(result.nextTime, isNull);
      expect(result.untilNext, isNull);
      expect(result.tomorrowFirstTime, '07:30');
    });

    test('yarin farkli gun tipindeyse o tarifenin ilki alinir', () {
      // Cuma aksami -> yarin Cumartesi, hafta sonu tarifesi gecerli.
      final result = build(
        showWeekend: false,
        now: DateTime(2026, 7, 31, 19, 0),
      );

      expect(result.nextTime, isNull);
      expect(result.tomorrowFirstTime, '09:00');
    });
  });

  group('secili gun tipi bugun degilse', () {
    test('canli geri sayim uretilmez', () {
      // Pazartesi gunu hafta sonu tarifesine bakiliyor.
      final result = build(showWeekend: true, now: monday);

      expect(result.isToday, isFalse);
      expect(result.nextTime, isNull);
      expect(result.untilNext, isNull);
      expect(result.times, weekend);
    });

    test('hafta sonu gunu hafta ici tarifesi de bugun sayilmaz', () {
      final result = build(showWeekend: false, now: saturday);

      expect(result.isToday, isFalse);
      expect(result.times, weekday);
    });
  });

  group('bozuk ve eksik veri', () {
    test('bos tarife cokmeye yol acmaz', () {
      final result = build(
        showWeekend: false,
        now: monday,
        weekdayTimes: const [],
      );

      expect(result.times, isEmpty);
      expect(result.nextTime, isNull);
      expect(result.progress, isNull);
    });

    test('gecersiz saat bicimleri siradaki kalkisi bozmaz', () {
      final result = build(
        showWeekend: false,
        now: monday,
        weekdayTimes: const ['bozuk', '25:99', '13:50'],
      );

      expect(result.nextTime, '13:50');
    });

    test('saatler girildikleri sirada olmasa da siralanir', () {
      final result = build(
        showWeekend: false,
        now: DateTime(2026, 7, 27, 6, 0),
        weekdayTimes: const ['13:20', '07:30', '08:00'],
      );

      expect(result.times, ['07:30', '08:00', '13:20']);
      expect(result.nextTime, '07:30');
    });
  });

  group('isWeekendDay', () {
    test('cumartesi ve pazari hafta sonu sayar', () {
      expect(RingDepartures.isWeekendDay(DateTime(2026, 8, 1)), isTrue);
      expect(RingDepartures.isWeekendDay(DateTime(2026, 8, 2)), isTrue);
      expect(RingDepartures.isWeekendDay(DateTime(2026, 7, 31)), isFalse);
    });
  });
}
