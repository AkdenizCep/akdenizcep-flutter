import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/pages/components/direction_switcher.dart';
import 'package:akdenizcep/features/ring/pages/components/full_schedule_sheet.dart';
import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

void main() {
  final schedules = [
    RingSchedule(
      lineId: 'au102_gidis',
      weekday: const ['08:02'],
      weekend: const ['10:02'],
      stops: const [],
    ),
    RingSchedule(
      lineId: 'au102_donus',
      weekday: const ['08:12'],
      weekend: const ['10:12'],
      stops: const [],
    ),
    RingSchedule(
      lineId: 'au103_gidis',
      weekday: const ['08:03'],
      weekend: const ['10:03'],
      stops: const [],
    ),
    RingSchedule(
      lineId: 'au103_donus',
      weekday: const ['08:13'],
      weekend: const ['10:13'],
      stops: const [],
    ),
    RingSchedule(
      lineId: 'au104_gidis',
      weekday: const ['08:04'],
      weekend: const [],
      stops: const [],
    ),
  ];

  Widget wrap({List<RingSchedule>? values, bool isReturn = false}) {
    return ProviderScope(
      overrides: [
        ringSchedulesProvider.overrideWith(
          (ref) => Stream.value(values ?? schedules),
        ),
        routeShapesProvider.overrideWith((ref) async => routeBundle()),
        nowProvider.overrideWith((ref) => DateTime(2026, 8, 31, 7)),
        showWeekendProvider.overrideWith((ref) => false),
        isReturnDirectionProvider.overrideWith((ref) => isReturn),
      ],
      child: const MaterialApp(home: Scaffold(body: FullScheduleSheet())),
    );
  }

  testWidgets('tum tarifede hat ve yon degisince saatler guncellenir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('AÜ102'), findsOneWidget);
    expect(find.text('AÜ103'), findsOneWidget);
    expect(find.text('AÜ104'), findsNothing);
    expect(find.text('08:02'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(find.text('Adli Tıp'), findsOneWidget);
    expect(find.text('Meltem Kapısı'), findsOneWidget);

    await tester.tap(find.text('H.Sonu'));
    await tester.pumpAndSettle();
    expect(find.text('10:02'), findsOneWidget);

    await tester.tap(find.text('AÜ103'));
    await tester.pumpAndSettle();
    expect(find.text('10:03'), findsOneWidget);
    expect(find.text('10:02'), findsNothing);

    await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('10:13'), findsOneWidget);
    expect(find.text('10:03'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tek yonlu hatta gercek tarife yonunu gosterir', (tester) async {
    await tester.pumpWidget(wrap(values: [schedules.first], isReturn: true));
    await tester.pumpAndSettle();

    expect(find.text('08:02'), findsOneWidget);
    expect(find.text('Adli Tıp'), findsOneWidget);
    expect(find.text('Meltem Kapısı'), findsOneWidget);
    final switcher = tester.widget<DirectionSwitcher>(
      find.byType(DirectionSwitcher),
    );
    expect(switcher.route, (from: 'Adli Tıp', to: 'Meltem Kapısı'));
    expect(switcher.canSwitch, isFalse);
    expect(
      tester.getSemantics(find.byType(DirectionSwitcher)).label,
      contains('Yön değiştirilemez'),
    );
    expect(tester.takeException(), isNull);
  });
}
