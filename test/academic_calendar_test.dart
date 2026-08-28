import 'package:akdenizcep/features/campus/models/academic_calendar.dart';
import 'package:akdenizcep/features/campus/pages/components/academic_calendar_format.dart';
import 'package:akdenizcep/features/campus/services/academic_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
  });

  final service = AcademicCalendarService();

  group('AcademicCalendarService veri bütünlüğü', () {
    test('her dönüm noktasının hem güz hem bahar tarihi vardır', () {
      for (final milestone in service.milestones) {
        expect(
          milestone.fall,
          isNotNull,
          reason: '${milestone.title} güz tarihi eksik',
        );
        expect(
          milestone.spring,
          isNotNull,
          reason: '${milestone.title} bahar tarihi eksik',
        );
      }
    });

    test('aralıklarda bitiş başlangıçtan önce olamaz', () {
      for (final milestone in service.milestones) {
        for (final range in [milestone.fall, milestone.spring]) {
          if (range?.end == null) continue;
          expect(
            range!.end!.isBefore(range.start),
            isFalse,
            reason: '${milestone.title}: bitiş başlangıçtan önce',
          );
        }
      }
    });

    test('güz tarihleri baharın tümünden önce gelir', () {
      // Takvim tek bir akademik yılı kapsıyor: güz 2026 sonbaharında,
      // bahar 2027 ilkbaharında. Yanlış yıla yazılmış bir tarih bu testi
      // kırar.
      for (final milestone in service.milestones) {
        expect(
          milestone.fall!.start.isBefore(milestone.spring!.start),
          isTrue,
          reason: '${milestone.title}: güz baharı geçiyor',
        );
      }
    });

    test('derslerin başlaması hem güzde hem baharda kayıtlı', () {
      final start = service.milestones.firstWhere(
        (m) => m.title == 'Derslerin Başlaması',
      );
      expect(start.fall!.start, DateTime(2026, 9, 14));
      expect(start.spring!.start, DateTime(2027, 2, 1));
    });

    test('resmi tatiller tarih sırasına göre girilmiş', () {
      for (var i = 1; i < service.holidays.length; i++) {
        final prev = service.holidays[i - 1].date;
        final curr = service.holidays[i].date;
        expect(
          curr.isAfter(prev),
          isTrue,
          reason: '${service.holidays[i].title} sıralamayı bozuyor',
        );
      }
    });

    test('yarım gün tatiller doğru işaretli', () {
      final halfDays = service.holidays.where((h) => h.halfDay);
      expect(halfDays.map((h) => h.title), [
        'Cumhuriyet Bayramı',
        'Ramazan Bayramı Arefesi',
        'Kurban Bayramı Arefesi',
      ]);
    });
  });

  group('AcademicCalendarService.currentTerm', () {
    test('bahar başlamadan önce güz döner', () {
      expect(service.currentTerm(DateTime(2026, 8, 28)), AcademicTerm.fall);
      expect(service.currentTerm(DateTime(2027, 1, 31)), AcademicTerm.fall);
    });

    test('bahar başladıktan sonra bahar döner', () {
      expect(service.currentTerm(DateTime(2027, 2, 1)), AcademicTerm.spring);
      expect(service.currentTerm(DateTime(2027, 6, 1)), AcademicTerm.spring);
    });
  });

  group('AcademicCalendarService.upcomingEvents', () {
    test('geçmiş tarihler listeye girmez', () {
      final events = service.upcomingEvents(DateTime(2027, 8, 31));
      expect(events, isEmpty);
    });

    test('bugünden itibaren en yakın olay ilk sırada', () {
      final events = service.upcomingEvents(DateTime(2026, 8, 28));
      expect(events.first.date, DateTime(2026, 9, 7));
      expect(events.first.title, contains('Katkı Payı'));
    });

    test('bugünün tarihi de dahil edilir', () {
      final events = service.upcomingEvents(DateTime(2026, 9, 14));
      expect(events.first.date, DateTime(2026, 9, 14));
    });

    test('tatiller ve akademik tarihler tek zaman çizelgesinde karışık sıralanır', () {
      final events = service.upcomingEvents(DateTime(2026, 10, 1));
      final firstHolidayIndex = events.indexWhere((e) => e.isHoliday);
      expect(firstHolidayIndex, greaterThan(0));
      expect(events[firstHolidayIndex].title, 'Cumhuriyet Bayramı');
      expect(events[firstHolidayIndex].date, DateTime(2026, 10, 28));
    });

    group('devam eden aralıklar (bir sürecin ortasındayken)', () {
      // 9 Eylül 2026: "Katkı Payı Yatırma" (7-11 Eylül) ve "Danışman Onayı"
      // (7-13 Eylül) aynı anda devam ediyor. İkisi de baslamis olsa da
      // listeden düşmemeli — en erken bitecek olan öne geçmeli.
      test('devam eden süreç, başlamamış bir sonraki olayın önüne geçer', () {
        final events = service.upcomingEvents(DateTime(2026, 9, 9));

        expect(events.first.title, contains('Katkı Payı'));
        expect(events.first.isOngoingOn(DateTime(2026, 9, 9)), isTrue);
        expect(events[1].title, contains('Danışman Onayı'));
      });

      test('bitiş günü hâlâ devam eden sayılır (dahil)', () {
        final events = service.upcomingEvents(DateTime(2026, 9, 11));

        expect(events.first.title, contains('Katkı Payı'));
        expect(events.first.isOngoingOn(DateTime(2026, 9, 11)), isTrue);
      });

      test('bitişten bir gün sonra o dönemin süreci listeden düşer', () {
        final events = service.upcomingEvents(DateTime(2026, 9, 12));

        // Güz'ün "Katkı Payı" penceresi (7-11 Eylül) kapandı; aynı başlıklı
        // Bahar örneği (25-29 Ocak 2027) gelecekte olduğu için listede
        // kalmaya devam eder — yalnızca geçmişteki örnek düşmeli.
        final katkiPayiDates = events
            .where((e) => e.title.contains('Katkı Payı'))
            .map((e) => e.date);
        expect(katkiPayiDates, isNot(contains(DateTime(2026, 9, 7))));
        expect(katkiPayiDates, contains(DateTime(2027, 1, 25)));
        expect(events.first.title, contains('Danışman Onayı'));
      });

      test('tekil günlük olay hiçbir zaman "devam eden" sayılmaz', () {
        final events = service.upcomingEvents(DateTime(2026, 9, 14));
        final derslerinBaslamasi = events.firstWhere(
          (e) => e.title == 'Derslerin Başlaması',
        );

        expect(derslerinBaslamasi.isRange, isFalse);
        expect(
          derslerinBaslamasi.isOngoingOn(DateTime(2026, 9, 14)),
          isFalse,
        );
      });
    });
  });

  group('formatAcademicRange', () {
    test('tekil tarihi tek gün olarak yazar', () {
      expect(
        formatAcademicRange(AcademicDateRange(DateTime(2026, 9, 14))),
        '14 Eylül 2026',
      );
    });

    test('aynı ay içindeki aralığı kısaltır', () {
      expect(
        formatAcademicRange(
          AcademicDateRange(DateTime(2026, 9, 7), DateTime(2026, 9, 11)),
        ),
        '7-11 Eylül 2026',
      );
    });

    test('farklı aylar arasındaki aralığı tam yazar', () {
      expect(
        formatAcademicRange(
          AcademicDateRange(DateTime(2026, 9, 14), DateTime(2026, 12, 20)),
        ),
        '14 Eylül - 20 Aralık 2026',
      );
    });
  });
}
