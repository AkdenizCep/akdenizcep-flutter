import 'package:akdenizcep/features/ring/models/ring_departures.dart';
import 'package:akdenizcep/features/ring/models/ring_schedule.dart';
import 'package:akdenizcep/features/ring/pages/components/stop_map_card.dart';
import 'package:akdenizcep/features/ring/providers/ring_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ring_fixtures.dart';

/// Harita ekranindaki durak karti sabit yukseklikli bir seritte duruyor;
/// icerigi tasarsa kullaniciya sari-siyah bant olarak gorunur.
///
/// Kart bilincli olarak kompakt: kalkis saatleri buraya konmaz, cunku serit
/// haritanin ustunde durur ve yukseldikce haritayi yer. Saatler durak
/// yapraginda gosterilir.
void main() {
  final testStop = stop(
    'durak_1',
    name: 'AKDENİZ ÜNİVERSİTESİ MERKEZİ YEMEKHANE',
    servedBy: [service('AÜ102'), service('AÜ103', isReturn: true)],
  );

  final schedules = [
    RingSchedule(
      lineId: 'au102_gidis',
      weekday: const ['06:31', '23:55'],
      weekend: const [],
      stops: const ['durak_1'],
    ),
    RingSchedule(
      lineId: 'au103_donus',
      weekday: const ['06:41', '23:50'],
      weekend: const [],
      stops: const ['durak_1'],
    ),
  ];

  final nearby = NearbyStop(
    stop: testStop,
    distanceMeters: 553,
    schedules: schedules,
  );

  /// Seritteki gercek kisit: 274 genislik, 156 yukseklik.
  Widget wrap({required DateTime now}) {
    return ProviderScope(
      overrides: [
        ringStopsProvider.overrideWith((ref) => [testStop]),
        ringSchedulesProvider.overrideWith((ref) => Stream.value(schedules)),
        nowProvider.overrideWith((ref) => now),
        // showWeekendProvider'in varsayilani GERCEK DateTime.now()'a bakar;
        // sahte `now` ile tutarli olmazsa "bugun" hesabi celisir. Bkz.
        // stop_detail_sheet_test.dart'taki ayni duzeltme.
        showWeekendProvider.overrideWith(
          (ref) => RingDepartures.isWeekendDay(now),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 156,
              width: 274,
              child: StopMapCard(
                nearby: nearby,
                isSelected: true,
                onShowLines: () {},
                onWalkingDirections: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('kart 274x156 seride tasmadan sigar', (tester) async {
    await tester.pumpWidget(wrap(now: DateTime(2026, 7, 27, 23, 43)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Merkezi Yemekhane'), findsOneWidget);
    expect(find.text('553 m · ~7 dk yürüme'), findsOneWidget);
    expect(find.text('AÜ102'), findsOneWidget);
    expect(find.text('AÜ103'), findsOneWidget);
    expect(find.text('Hatları gör'), findsOneWidget);
  });

  testWidgets('kart kalkis saati gostermez — o bilgi durak yapraginda', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(now: DateTime(2026, 7, 27, 23, 43)));
    await tester.pump();

    expect(find.textContaining('kalkış'), findsNothing);
    expect(find.textContaining('23:50'), findsNothing);
  });

  testWidgets('bugun sefer kalmadiginda da ayni kompakt kart cizilir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(now: DateTime(2026, 7, 27, 23, 58)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Merkezi Yemekhane'), findsOneWidget);
    expect(find.text('Hatları gör'), findsOneWidget);
  });
}
