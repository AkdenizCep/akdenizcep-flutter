import 'package:akdenizcep/features/ring/models/ring_departures.dart';
import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/pages/components/bus_stop_icon.dart';
import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

/// Durak ikonu hat rengiyle boyanir. Renk kurali tek yerde (busStopColor) ve
/// rozetle ayni paleti (lineColors) kullanir: ilk hat primary, ikinci hat
/// onSurface.
void main() {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
  const lines = ['au102', 'au103'];

  group('busStopColor', () {
    test('siradaki seferin hatti oncelikli', () {
      final color = busStopColor(
        colorScheme,
        lines,
        soonestLineCode: 'au103',
        stopLineNames: const ['AÜ102'],
      );

      expect(color, colorScheme.onSurface);
    });

    test('seferi olmayan tek hatli durak kendi hattinin rengini alir', () {
      expect(
        busStopColor(colorScheme, lines, stopLineNames: const ['AÜ102']),
        colorScheme.primary,
      );
      expect(
        busStopColor(colorScheme, lines, stopLineNames: const ['AÜ103']),
        colorScheme.onSurface,
      );
    });

    test('seferi olmayan iki hatli durak notr primary alir', () {
      final color = busStopColor(
        colorScheme,
        lines,
        stopLineNames: const ['AÜ102', 'AÜ103'],
      );

      expect(color, colorScheme.primary);
    });

    test('bilinmeyen hat primary\'e duser', () {
      expect(
        busStopColor(colorScheme, lines, soonestLineCode: 'au999'),
        colorScheme.primary,
      );
      expect(
        busStopColor(colorScheme, const [], stopLineNames: const ['AÜ103']),
        colorScheme.primary,
      );
    });
  });

  group('BusStopIcon', () {
    testWidgets('SVG verilen rengi currentColor olarak tasir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BusStopIcon(color: Color(0xFFC62828), size: 30)),
        ),
      );

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final loader = svg.bytesLoader as SvgAssetLoader;

      expect(loader.assetName, 'assets/images/bus-stop.svg');
      expect(loader.theme?.currentColor, const Color(0xFFC62828));
      expect(svg.width, 30);
      expect(svg.height, 30);
    });
  });

  group('StopBusIcon', () {
    final testStop = stop(
      'durak_1',
      name: 'MERKEZİ YEMEKHANE',
      servedBy: [service('AÜ102'), service('AÜ103', isReturn: true)],
    );

    // 102'nin siradaki seferi 06:31, 103'unki 06:41 -> 06:30'da 102 once.
    final schedules = [
      RingSchedule(
        lineId: 'au102_gidis',
        weekday: const ['06:31'],
        weekend: const [],
        stops: const ['durak_1'],
      ),
      RingSchedule(
        lineId: 'au103_donus',
        weekday: const ['06:41'],
        weekend: const [],
        stops: const ['durak_1'],
      ),
    ];

    Widget wrap(DateTime now) {
      return ProviderScope(
        overrides: [
          ringStopsProvider.overrideWith((ref) => [testStop]),
          ringSchedulesProvider.overrideWith((ref) => Stream.value(schedules)),
          nowProvider.overrideWith((ref) => now),
          showWeekendProvider.overrideWith(
            (ref) => RingDepartures.isWeekendDay(now),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: StopBusIcon(stop: testStop)),
        ),
      );
    }

    testWidgets('iki hatli durakta siradaki seferin hat rengini kullanir', (
      tester,
    ) async {
      // Hafta ici sabah 06:35: 102 kalkti, siradaki sefer 103 (06:41).
      await tester.pumpWidget(wrap(DateTime(2026, 7, 27, 6, 35)));
      await tester.pump();

      final context = tester.element(find.byType(StopBusIcon));
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final loader = svg.bytesLoader as SvgAssetLoader;

      expect(
        loader.theme?.currentColor,
        Theme.of(context).colorScheme.onSurface,
      );
    });
  });
}
