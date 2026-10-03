import 'package:akdenizcep/app/theme.dart';
import 'package:akdenizcep/features/home/models/day_part.dart';
import 'package:akdenizcep/features/home/models/sky_position.dart';
import 'package:akdenizcep/features/home/pages/components/home_greeting.dart';
import 'package:akdenizcep/features/home/pages/components/horizon_vignette.dart';
import 'package:akdenizcep/shared/services/academic_calendar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayPart.at', () {
    DayPart at(int hour, [int minute = 0]) =>
        DayPart.at(DateTime(2026, 10, 3, hour, minute));

    test('sınırlar doğru dilime düşer', () {
      expect(at(4, 59), DayPart.night);
      expect(at(5), DayPart.morning);
      expect(at(11, 59), DayPart.morning);
      expect(at(12), DayPart.afternoon);
      expect(at(17, 59), DayPart.afternoon);
      expect(at(18), DayPart.evening);
      expect(at(21, 59), DayPart.evening);
      expect(at(22), DayPart.night);
      expect(at(0), DayPart.night);
    });

    test('selam metinleri', () {
      expect(DayPart.morning.greeting, 'Günaydın');
      expect(DayPart.afternoon.greeting, 'İyi günler');
      expect(DayPart.evening.greeting, 'İyi akşamlar');
      expect(DayPart.night.greeting, 'İyi geceler');
    });
  });

  group('skyPositionAt', () {
    // 15 Ekim 2026: tablodaki değerler birebir geçerli, gün doğumu 07:03
    // (423 dk), gün batımı 18:22 (1102 dk).
    SkyPosition at(int hour, int minute) =>
        skyPositionAt(DateTime(2026, 10, 15, hour, minute));

    test('gün doğumundan önce gece, sonra gündüz', () {
      expect(at(7, 0).isDay, isFalse);
      final risen = at(7, 10);
      expect(risen.isDay, isTrue);
      expect(risen.progress, closeTo(0, 0.02));
    });

    test('öğle civarında güneş yayın ortasında', () {
      final noon = at(13, 0);
      expect(noon.isDay, isTrue);
      expect(noon.progress, closeTo(0.5, 0.05));
    });

    test('gün batımından sonra gece başlar', () {
      expect(at(18, 10).isDay, isTrue);
      final dusk = at(18, 30);
      expect(dusk.isDay, isFalse);
      expect(dusk.progress, closeTo(0, 0.02));
    });

    test('gece yarısı geceyi ortalar, ilerleme 0..1 içinde kalır', () {
      final midnight = skyPositionAt(DateTime(2026, 10, 15, 0, 30));
      expect(midnight.isDay, isFalse);
      expect(midnight.progress, inInclusiveRange(0.0, 1.0));
    });

    test('kış akşamı erken kararır, yaz akşamı geç', () {
      // Aralık 17:30: batım 17:42 civarı, hâlâ gündüz. 18:00 gece.
      expect(skyPositionAt(DateTime(2026, 12, 15, 17, 30)).isDay, isTrue);
      expect(skyPositionAt(DateTime(2026, 12, 15, 18, 0)).isDay, isFalse);
      // Haziran 19:30 hâlâ gündüz.
      expect(skyPositionAt(DateTime(2026, 6, 15, 19, 30)).isDay, isTrue);
    });

    test('ay geçişlerinde sıçrama olmaz', () {
      final lastOfMonth = skyPositionAt(DateTime(2026, 9, 30, 7, 0));
      final firstOfNext = skyPositionAt(DateTime(2026, 10, 1, 7, 0));
      expect(lastOfMonth.isDay, firstOfNext.isDay);
    });

    test('yıl dönümünde (Aralık - Ocak) tablo başa sarar', () {
      expect(() => skyPositionAt(DateTime(2026, 12, 31, 12)), returnsNormally);
      expect(() => skyPositionAt(DateTime(2027, 1, 1, 12)), returnsNormally);
      expect(skyPositionAt(DateTime(2027, 1, 1, 12)).isDay, isTrue);
    });
  });

  group('HomeGreeting', () {
    final service = AcademicCalendarService();
    final morning = DateTime(2026, 10, 3, 9);

    Future<void> pump(
      WidgetTester tester, {
      required String? firstName,
      required DateTime now,
      bool withTerm = true,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 400);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HomeGreeting(
              firstName: firstName,
              now: now,
              termProgress: withTerm ? service.termProgress(now) : null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('selam, isim ve yarıyıl haftası görünür', (tester) async {
      await pump(tester, firstName: 'Erhan', now: morning);

      expect(find.text('Günaydın, Erhan'), findsOneWidget);
      expect(find.text('Güz Yarıyılı, 3. hafta'), findsOneWidget);
      expect(find.byType(HorizonVignette), findsOneWidget);
    });

    testWidgets('dönem dışında ikinci satır yoktur', (tester) async {
      await pump(
        tester,
        firstName: 'Erhan',
        now: DateTime(2027, 7, 1, 20),
        withTerm: true,
      );

      expect(find.text('İyi akşamlar, Erhan'), findsOneWidget);
      expect(find.textContaining('Yarıyılı'), findsNothing);
    });

    testWidgets('isim yoksa yalnızca selam yazılır', (tester) async {
      await pump(tester, firstName: null, now: morning);
      expect(find.text('Günaydın'), findsOneWidget);

      await pump(tester, firstName: '  ', now: morning);
      expect(find.text('Günaydın'), findsOneWidget);
    });

    testWidgets('ufuk çizimi ekran okuyucudan gizlidir', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, firstName: 'Erhan', now: morning);

      final excluded = find.descendant(
        of: find.byType(HorizonVignette),
        matching: find.byType(ExcludeSemantics),
      );
      expect(excluded, findsOneWidget);
      expect(tester.widget<ExcludeSemantics>(excluded).excluding, isTrue);
      expect(
        tester.getSemantics(find.text('Günaydın, Erhan')).label,
        'Günaydın, Erhan',
      );
      handle.dispose();
    });
  });

  group('HorizonVignette', () {
    testWidgets('günün dört anında da hatasız çizilir', (tester) async {
      for (final now in [
        DateTime(2026, 10, 3, 6, 50),
        DateTime(2026, 10, 3, 13),
        DateTime(2026, 10, 3, 18, 15),
        DateTime(2026, 10, 3, 23),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(child: HorizonVignette(now: now)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$now');
        expect(
          tester.getSize(find.byType(HorizonVignette)),
          const Size(HorizonVignette.width, HorizonVignette.height),
        );
      }
    });

    testWidgets('hareket azaltma açıkken animasyon beklemez', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: HorizonVignette(now: DateTime(2026, 10, 3, 13)),
            ),
          ),
        ),
      );
      // pumpAndSettle yok: ilk karede animasyon zaten bitmiş olmalı.
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
