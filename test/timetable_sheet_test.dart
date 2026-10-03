import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/pages/components/timetable_sheet.dart';
import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

void main() {
  // 2026-07-27 Pazartesi.
  final schedules = [
    RingSchedule(
      lineId: 'au102_gidis',
      weekday: const ['13:50', '14:15', '14:30', '15:05'],
      weekend: const ['10:00', '11:00'],
    ),
    RingSchedule(
      lineId: 'au103_gidis',
      weekday: const ['14:20', '14:35'],
      weekend: const ['10:10'],
    ),
    RingSchedule(
      lineId: 'au102_donus',
      weekday: const ['14:00', '14:40'],
      weekend: const ['12:00'],
    ),
    RingSchedule(
      lineId: 'au103_donus',
      weekday: const ['14:10'],
      weekend: const ['12:10'],
    ),
  ];

  Widget wrap({DateTime? now}) => ProviderScope(
    overrides: [
      ringSchedulesProvider.overrideWith((ref) => Stream.value(schedules)),
      routeShapesProvider.overrideWith((ref) async => routeBundle()),
      nowProvider.overrideWith((ref) => now ?? DateTime(2026, 7, 27, 14, 22)),
    ],
    child: const MaterialApp(home: Scaffold(body: TimetableSheet())),
  );

  testWidgets('bugunun gun tipi ve ilk kalkis noktasi secili acilir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tüm Tarife'), findsOneWidget);
    expect(find.text('Adli Tıp'), findsOneWidget);
    expect(find.text('Meltem Kapısı'), findsOneWidget);
    expect(find.text('Hafta içi'), findsOneWidget);
    expect(find.text('Hafta sonu'), findsOneWidget);
    expect(find.text('Bugün'), findsNothing);

    // Adli Tip sutunlari: AÜ102 ve AÜ103 yan yana.
    expect(find.text('AÜ102'), findsOneWidget);
    expect(find.text('AÜ103'), findsOneWidget);
    expect(find.text('14:30'), findsOneWidget);
    expect(find.text('14:20'), findsOneWidget);
    expect(find.text('14:00'), findsNothing);
    expect(find.text('Saatler kalkış noktasına aittir.'), findsOneWidget);
  });

  testWidgets(
    'siradaki sefer hat renginde dolu ve dk gosterir, son sefer SON',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // AÜ102: 14:15 gecmis, 14:30 sirada (8 dk). AÜ103: 14:35 sirada (13 dk).
      expect(find.text('8 dk'), findsOneWidget);
      expect(find.text('13 dk'), findsOneWidget);

      final primary = Theme.of(
        tester.element(find.text('Tüm Tarife')),
      ).colorScheme.primary;
      final cell = tester.widget<Container>(
        find
            .ancestor(of: find.text('14:30'), matching: find.byType(Container))
            .first,
      );
      expect((cell.decoration as BoxDecoration).color, primary);

      // Son sefer: AÜ102 15:05 ve AÜ103 14:35 (ikisi de SON).
      expect(find.text('SON'), findsNWidgets(2));
    },
  );

  testWidgets('hafta sonu secilince gecmis/siradaki durumlari kalkar', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hafta sonu'));
    await tester.pumpAndSettle();

    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('11:00'), findsOneWidget);
    expect(find.textContaining(' dk'), findsNothing);
    expect(find.text('14:30'), findsNothing);
  });

  testWidgets('kalkis noktasi degisince diger noktanin saatleri gelir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meltem Kapısı'));
    await tester.pumpAndSettle();

    expect(find.text('14:40'), findsOneWidget);
    expect(find.text('14:10'), findsOneWidget);
    expect(find.text('14:30'), findsNothing);
  });
}
